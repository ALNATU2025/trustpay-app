import 'dart:math' as math;

import '../models/models.dart';

/// Sample values from the design. Replace these with data from your API.
const double kAccountBalance = 12450;
const String kAccountName = 'Aminata Kamara';
const String kAccountNumber = '0123454821';
const String kPhone = '076 123 456';
const String kBusinessName = 'Kamara Stores';
const String kEmail = 'aminata.kamara@example.com';
const String kTier = 'Tier 2 · Verified';

/// Shows the Admin console in the menu. TODO: set this from the role your API
/// returns after login. The server must also check the role on every admin
/// request; hiding the menu item is not security.
const bool kIsAdmin = true;

/// Placeholder support details. Replace with your real ones.
const String kSupportPhone = '+232 00 000 000';
const String kSupportEmail = 'support@trustpay.example';

/// Sierra Leone banks shown in transfers. Replace with the list from your payment partner.
const kBanks = [
  'Rokel Commercial Bank',
  'Sierra Leone Commercial Bank',
  'Ecobank',
  'GTBank',
  'Union Trust Bank',
  'Access Bank',
  'First Bank',
  'Zenith Bank',
];

/// Sierra Leone mobile money wallets.
const kMobileMoney = ['Orange Money', 'Afrimoney', 'Qmoney'];
const kNetworks = ['Orange', 'Africell', 'Qcell'];

/// Reference such as `TP-TRF-111026-2048` (code, day-month-year, 4 digits).
String makeReference(String code) {
  final n = DateTime.now();
  final date = '${n.day.toString().padLeft(2, '0')}'
      '${n.month.toString().padLeft(2, '0')}'
      '${(n.year % 100).toString().padLeft(2, '0')}';
  final rand = 1000 + math.Random().nextInt(9000);
  return 'TP-$code-$date-$rand';
}

/// 20-digit sample token in groups of four. Your power vendor returns the real one.
String makeToken() {
  final r = math.Random();
  final groups = List.generate(
    5,
    (_) => (1000 + r.nextInt(9000)).toString(),
  );
  return groups.join(' ');
}

// ---------------------------------------------------------------- lookups

/// Sample bank account name lookup. Replace with your name-enquiry API.
Future<String?> lookupBankAccount(String bank, String number) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return number.length == 10 ? 'Fatmata Conteh' : null;
}

class MeterInfo {
  const MeterInfo(this.name, this.address);

  final String name;
  final String address;
}

/// Sample meter validation. Replace with your bills provider API.
Future<MeterInfo?> lookupMeter(String provider, String meter) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return meter.length == 11
      ? const MeterInfo('AMINATA KAMARA', '12 Wilberforce Street, Freetown')
      : null;
}

// ---------------------------------------------------------------- bills

class BillProvider {
  const BillProvider(this.name, this.subtitle);

  final String name;
  final String subtitle;
}

const kElectricityProviders = [
  BillProvider('EDSA Cash Power', 'Prepaid · Freetown'),
  BillProvider('EDSA Cash Power (Provinces)', 'Prepaid · Bo, Kenema, Makeni'),
  BillProvider('EDSA Postpaid', 'Postpaid · Freetown'),
];

const kTvProviders = [
  BillProvider('DStv', 'Subscriptions · Sierra Leone'),
  BillProvider('GOtv', 'Subscriptions · Sierra Leone'),
  BillProvider('StarTimes', 'Subscriptions · Sierra Leone'),
];

const kInternetProviders = [
  BillProvider('Orange Internet', 'Data plans · Sierra Leone'),
  BillProvider('Africell Data', 'Data plans · Sierra Leone'),
  BillProvider('Sierratel', 'Broadband · Freetown'),
];

// ---------------------------------------------------------------- data plans

class DataPlan {
  const DataPlan(this.size, this.days, this.price);

  final String size;
  final int days;
  final double price;

  String get validity => '$days days validity';
}

const kDataPlans = [
  DataPlan('500 MB', 7, 25),
  DataPlan('1.5 GB', 30, 75),
  DataPlan('3 GB', 30, 125),
  DataPlan('10 GB', 30, 300),
];

// ---------------------------------------------------------------- transactions

enum TxnKind { transfer, funding, bill, airtime }

class Txn {
  const Txn({
    required this.title,
    required this.meta,
    required this.amount,
    required this.kind,
    required this.date,
    this.status = 'Successful',
    this.receipt,
  });

  final String title;
  final String meta;
  final double amount;
  final TxnKind kind;
  final DateTime date;
  final String status;
  final ReceiptData? receipt;

  bool get isCredit => amount > 0;
}

final List<Txn> kSampleTransactions = [
  Txn(
    title: 'To Fatmata Conteh',
    meta: '12:50 · Successful · Includes Le 1 fee',
    amount: -1251,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 11, 12, 50),
    receipt: ReceiptData.transfer(
      const TransferDraft(
        bank: 'Rokel Commercial Bank',
        accountNumber: '0123456789',
        accountName: 'Fatmata Conteh',
        amount: 1250,
        note: 'October supplies',
      ),
      'TP-TRF-111026-2048',
      DateTime(2026, 10, 11, 12, 50),
    ),
  ),
  Txn(
    title: 'From Mohamed Sesay',
    meta: '10:24 · Bank transfer · Successful',
    amount: 1250,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 11, 10, 24),
  ),
  Txn(
    title: 'EDSA Cash Power',
    meta: '09:18 · Electricity · Successful',
    amount: -625,
    kind: TxnKind.bill,
    date: DateTime(2026, 10, 11, 9, 18),
  ),
  Txn(
    title: 'To Fatmata Conteh',
    meta: '16:20 · Bank transfer · Successful',
    amount: -400,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 10, 16, 20),
  ),
  Txn(
    title: 'Orange Airtime',
    meta: '11:08 · 076 123 456 · Successful',
    amount: -50,
    kind: TxnKind.airtime,
    date: DateTime(2026, 10, 10, 11, 8),
  ),
  Txn(
    title: 'Account funding',
    meta: '08:45 · Rokel Commercial Bank · Successful',
    amount: 5000,
    kind: TxnKind.funding,
    date: DateTime(2026, 10, 9, 8, 45),
  ),
];
