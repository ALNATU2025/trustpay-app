import 'package:flutter/foundation.dart';

import '../utils/format.dart';

class TransferDraft {
  const TransferDraft({
    required this.bank,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    this.note = '',
  });

  final String bank;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String note;

  /// Sample fee from the design. Replace with the fee from your API.
  static const double fee = 10;

  double get total => amount + fee;

  String get maskedAccount =>
      '•• ${accountNumber.substring(accountNumber.length - 4)}';
}

class BillDraft {
  const BillDraft({
    required this.provider,
    required this.prepaid,
    required this.meter,
    required this.customer,
    required this.amount,
    required this.phone,
  });

  final String provider;
  final bool prepaid;
  final String meter;
  final String customer;
  final double amount;
  final String phone;

  static const double fee = 0;

  double get total => amount + fee;

  String get typeLabel => prepaid ? 'Prepaid' : 'Postpaid';
}

class VirtualCard {
  const VirtualCard({
    required this.last4,
    required this.expiry,
    required this.holder,
    required this.balance,
    required this.issuancePaid,
    this.frozen = false,
  });

  final String last4;
  final String expiry;
  final String holder;
  final double balance;
  final double issuancePaid;
  final bool frozen;

  VirtualCard copyWith({bool? frozen}) => VirtualCard(
        last4: last4,
        expiry: expiry,
        holder: holder,
        balance: balance,
        issuancePaid: issuancePaid,
        frozen: frozen ?? this.frozen,
      );
}

/// Holds the user's virtual card once one has been created.
final ValueNotifier<VirtualCard?> virtualCardNotifier = ValueNotifier(null);

class TerminalDraft {
  const TerminalDraft({
    required this.businessName,
    required this.category,
    required this.address,
    required this.city,
    required this.state,
    required this.contact,
  });

  final String businessName;
  final String category;
  final String address;
  final String city;
  final String state;
  final String contact;

  static const double deposit = 30000;
  static const double deliveryFee = 2500;

  double get total => deposit + deliveryFee;
}

class ReceiptData {
  const ReceiptData({
    required this.eyebrow,
    required this.statusLine,
    required this.bannerLabel,
    required this.amount,
    required this.rows,
  });

  final String eyebrow;
  final String statusLine;
  final String bannerLabel;
  final double amount;
  final List<(String, String)> rows;

  factory ReceiptData.transfer(TransferDraft d, String reference, DateTime at) {
    return ReceiptData(
      eyebrow: 'TRANSACTIONS · TRANSFER RECEIPT',
      statusLine: 'Successful · Bank transfer',
      bannerLabel: 'Sent to ${d.accountName}',
      amount: d.amount,
      rows: [
        ('Sender', 'Ada Okafor'),
        ('From account', 'TrustPay · 0123454821'),
        ('Recipient', d.accountName),
        ('Bank / account', '${d.bank} · ${d.accountNumber}'),
        (
          'Amount / fee',
          '${formatNaira(d.amount)} / ${formatNaira(TransferDraft.fee)}',
        ),
        ('Total debit', formatNaira(d.total)),
        if (d.note.trim().isNotEmpty) ('Note', d.note.trim()),
        ('Date & time', formatDateTime(at)),
        ('Reference', reference),
      ],
    );
  }
}
