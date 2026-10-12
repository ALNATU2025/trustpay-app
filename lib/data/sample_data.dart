import 'dart:math' as math;

import '../models/models.dart';

/// Sample values from the design. Replace these with data from your API.
const double kAccountBalance = 248500;
const String kAccountName = 'Ada Okafor';
const String kAccountNumber = '0123454821';
const String kPhone = '0803 456 7890';
const String kBusinessName = 'Ada Stores';
const String kEmail = 'ada.okafor@example.com';
const String kTier = 'Tier 2 · Verified';

/// Shows the Admin console in the menu. TODO: set this from the role your API
/// returns after login. The server must also check the role on every admin
/// request; hiding the menu item is not security.
const bool kIsAdmin = true;

/// Placeholder support details. Replace with your real ones.
const String kSupportPhone = '0700 000 0000';
const String kSupportEmail = 'support@trustpay.example';

const kBanks = ['GTBank', 'Access Bank', 'Zenith Bank', 'UBA', 'First Bank'];
const kNetworks = ['MTN', 'Airtel', 'Glo', '9mobile'];

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
  return number.length == 10 ? 'Tolu Adebayo' : null;
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
      ? const MeterInfo('ADA OKAFOR', '24 Allen Avenue, Ikeja')
      : null;
}

// ---------------------------------------------------------------- bills

class BillProvider {
  const BillProvider(this.name, this.subtitle);

  final String name;
  final String subtitle;
}

const kElectricityProviders = [
  BillProvider('Ikeja Electric', 'Prepaid & postpaid · Lagos'),
  BillProvider('Eko Electricity', 'Prepaid & postpaid · Lagos'),
  BillProvider('Abuja Electricity', 'Prepaid & postpaid · Abuja'),
];

const kTvProviders = [
  BillProvider('DStv', 'Subscriptions · Nigeria'),
  BillProvider('GOtv', 'Subscriptions · Nigeria'),
  BillProvider('StarTimes', 'Subscriptions · Nigeria'),
];

const kInternetProviders = [
  BillProvider('Spectranet', 'Data plans · Nigeria'),
  BillProvider('Smile', 'Data plans · Nigeria'),
  BillProvider('FibreOne', 'Broadband · Lagos'),
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
  DataPlan('500 MB', 7, 500),
  DataPlan('1.5 GB', 30, 1500),
  DataPlan('3 GB', 30, 2500),
  DataPlan('10 GB', 30, 6000),
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
    title: 'To Tolu Adebayo',
    meta: '12:50 · Successful · Includes ₦10 fee',
    amount: -25010,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 11, 12, 50),
    receipt: ReceiptData.transfer(
      const TransferDraft(
        bank: 'GTBank',
        accountNumber: '0123456789',
        accountName: 'Tolu Adebayo',
        amount: 25000,
        note: 'October supplies',
      ),
      'TP-TRF-111026-2048',
      DateTime(2026, 10, 11, 12, 50),
    ),
  ),
  Txn(
    title: 'From Chidi Okafor',
    meta: '10:24 · Bank transfer · Successful',
    amount: 25000,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 11, 10, 24),
  ),
  Txn(
    title: 'Ikeja Electric',
    meta: '09:18 · Electricity · Successful',
    amount: -12500,
    kind: TxnKind.bill,
    date: DateTime(2026, 10, 11, 9, 18),
  ),
  Txn(
    title: 'To Tolu Adebayo',
    meta: '16:20 · Bank transfer · Successful',
    amount: -8000,
    kind: TxnKind.transfer,
    date: DateTime(2026, 10, 10, 16, 20),
  ),
  Txn(
    title: 'MTN Airtime',
    meta: '11:08 · 0803 456 7890 · Successful',
    amount: -1000,
    kind: TxnKind.airtime,
    date: DateTime(2026, 10, 10, 11, 8),
  ),
  Txn(
    title: 'Account funding',
    meta: '08:45 · GTBank · Successful',
    amount: 100000,
    kind: TxnKind.funding,
    date: DateTime(2026, 10, 9, 8, 45),
  ),
];
