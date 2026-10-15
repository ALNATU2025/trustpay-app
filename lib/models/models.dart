import '../utils/format.dart';

// ------------------------------------------------------------- JSON helpers

Map<String, dynamic> asMap(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> asMapList(Object? v) => v is List
    ? [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ]
    : <Map<String, dynamic>>[];

List<String> asStrList(Object? v) => v is List ? [for (final e in v) '$e'] : <String>[];

double asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int asInt(Object? v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool asBool(Object? v) => v == true || v == 'true';

String asStr(Object? v, [String fallback = '']) => v == null ? fallback : '$v';

String? asStrOrNull(Object? v) {
  if (v == null) return null;
  final s = '$v';
  return s.isEmpty ? null : s;
}

/// A page of results from a paged endpoint.
class PagedList<T> {
  const PagedList(this.items, this.page, this.hasMore);

  final List<T> items;
  final int page;
  final bool hasMore;
}

// ------------------------------------------------------------------- user

class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.accountNumber,
    required this.businessName,
    required this.address,
    required this.tier,
    required this.role,
    required this.status,
    required this.onboardingStep,
    required this.hasPin,
    required this.balance,
  });

  factory User.fromJson(Map<String, dynamic> j) {
    final first = asStr(j['firstName']);
    final last = asStr(j['lastName']);
    final full = asStr(j['fullName']);
    return User(
      id: asStr(j['id'] ?? j['_id']),
      firstName: first,
      lastName: last,
      fullName: full.isNotEmpty ? full : '$first $last'.trim(),
      email: asStr(j['email']),
      phone: asStr(j['phone']),
      accountNumber: asStr(j['accountNumber']),
      businessName: asStr(j['businessName']),
      address: asStr(j['address']),
      tier: asStr(j['tier']),
      role: asStr(j['role'], 'user'),
      status: asStr(j['status'], 'active'),
      onboardingStep: asStr(j['onboardingStep'], 'done'),
      hasPin: asBool(j['hasPin']),
      balance: asDouble(j['balance']),
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String accountNumber;
  final String businessName;
  final String address;
  final String tier;

  /// `user`, `admin` or `support`.
  final String role;

  /// `active`, `suspended` or `pending_kyc`.
  final String status;

  /// `phone`, `identity`, `pin` or `done`.
  final String onboardingStep;
  final bool hasPin;
  final double balance;

  bool get isStaff => role == 'admin' || role == 'support';
  bool get isAdmin => role == 'admin';

  String get statusLabel => switch (status) {
        'active' => 'Verified',
        'pending_kyc' => 'Pending review',
        'suspended' => 'Suspended',
        _ => status,
      };

  User copyWith({double? balance}) => User(
        id: id,
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        email: email,
        phone: phone,
        accountNumber: accountNumber,
        businessName: businessName,
        address: address,
        tier: tier,
        role: role,
        status: status,
        onboardingStep: onboardingStep,
        hasPin: hasPin,
        balance: balance ?? this.balance,
      );
}

// ----------------------------------------------------------- transactions

enum TxnKind {
  transfer,
  funding,
  bill,
  airtime,
  data,
  tv,
  internet,
  card,
  pos,
  mobileMoney,
  other;

  static TxnKind parse(String? value) => switch (value) {
        'transfer' => TxnKind.transfer,
        'funding' => TxnKind.funding,
        'bill' => TxnKind.bill,
        'airtime' => TxnKind.airtime,
        'data' => TxnKind.data,
        'tv' => TxnKind.tv,
        'internet' => TxnKind.internet,
        'card' => TxnKind.card,
        'pos' => TxnKind.pos,
        'mobile_money' => TxnKind.mobileMoney,
        _ => TxnKind.other,
      };
}

/// The receipt the server builds for a transaction.
class ReceiptData {
  const ReceiptData({
    required this.eyebrow,
    required this.statusLine,
    required this.bannerLabel,
    required this.amount,
    required this.rows,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> j) {
    final rows = <(String, String)>[];
    final raw = j['rows'];
    if (raw is List) {
      for (final r in raw) {
        if (r is List && r.length >= 2) rows.add(('${r[0]}', '${r[1]}'));
      }
    }
    return ReceiptData(
      eyebrow: asStr(j['eyebrow'], 'TRANSACTIONS · RECEIPT'),
      statusLine: asStr(j['statusLine']),
      bannerLabel: asStr(j['bannerLabel']),
      amount: asDouble(j['amount']).abs(),
      rows: rows,
    );
  }

  final String eyebrow;
  final String statusLine;
  final String bannerLabel;
  final double amount;
  final List<(String, String)> rows;

  /// Plain text version, used by "Copy receipt".
  String toPlainText() {
    final b = StringBuffer('TrustPay receipt\n');
    if (bannerLabel.isNotEmpty) b.writeln(bannerLabel);
    b.writeln('Amount: ${formatLeone(amount)}');
    if (statusLine.isNotEmpty) b.writeln(statusLine);
    for (final r in rows) {
      b.writeln('${r.$1}: ${r.$2}');
    }
    return b.toString().trim();
  }
}

class Txn {
  const Txn({
    required this.id,
    required this.reference,
    required this.kind,
    required this.direction,
    required this.title,
    required this.meta,
    required this.amount,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.receipt,
    this.token,
  });

  factory Txn.fromJson(Map<String, dynamic> j) {
    final receipt = j['receipt'];
    return Txn(
      id: asStr(j['id'] ?? j['_id']),
      reference: asStr(j['reference']),
      kind: TxnKind.parse(asStrOrNull(j['kind'])),
      direction: asStr(j['direction']),
      title: asStr(j['title']),
      meta: asStr(j['meta']),
      amount: asDouble(j['amount']),
      fee: asDouble(j['fee']),
      status: asStr(j['status'], 'Successful'),
      createdAt: parseDate(j['createdAt']),
      receipt: receipt is Map ? ReceiptData.fromJson(Map<String, dynamic>.from(receipt)) : null,
      token: asStrOrNull(j['token']),
    );
  }

  final String id;
  final String reference;
  final TxnKind kind;

  /// `debit` or `credit`.
  final String direction;
  final String title;
  final String meta;

  /// Signed by the server: debits are negative.
  final double amount;
  final double fee;

  /// `Successful`, `Pending` or `Failed`.
  final String status;
  final DateTime createdAt;
  final ReceiptData? receipt;

  /// Electricity token for prepaid meters.
  final String? token;

  DateTime get date => createdAt;

  bool get isCredit => direction == 'credit' || (direction.isEmpty && amount > 0);

  /// Positive for money in, negative for money out, whatever sign the server used.
  double get signedAmount => isCredit ? amount.abs() : -amount.abs();

  /// Reference, fee and time, to add under the rows a screen already shows.
  List<(String, String)> get summaryRows => [
        if (fee > 0) ('Fee', formatLeone(fee)),
        if (reference.isNotEmpty) ('Reference', reference),
        ('Date & time', formatDateTime(createdAt)),
      ];
}

/// Response of every payment: the new transaction and the new balance. Extra
/// objects (`card`, `request`) stay in [raw].
class PaymentResult {
  const PaymentResult({required this.transaction, required this.balance, required this.raw});

  factory PaymentResult.fromJson(Map<String, dynamic> j) => PaymentResult(
        transaction: Txn.fromJson(asMap(j['transaction'])),
        balance: asDouble(j['balance']),
        raw: j,
      );

  final Txn transaction;
  final double balance;
  final Map<String, dynamic> raw;

  CardInfo? get card => raw['card'] is Map ? CardInfo.fromJson(asMap(raw['card'])) : null;

  Map<String, dynamic> get request => asMap(raw['request']);
}

// ------------------------------------------------------------------ cards

class CardInfo {
  const CardInfo({
    required this.id,
    required this.type,
    required this.last4,
    required this.expiry,
    required this.holder,
    required this.balance,
    required this.frozen,
    required this.status,
    required this.issuancePaid,
  });

  factory CardInfo.fromJson(Map<String, dynamic> j) => CardInfo(
        id: asStr(j['id'] ?? j['_id']),
        type: asStr(j['type'], 'virtual'),
        last4: asStr(j['last4']),
        expiry: asStr(j['expiry']),
        holder: asStr(j['holder']),
        balance: asDouble(j['balance']),
        frozen: asBool(j['frozen']),
        status: asStr(j['status']),
        issuancePaid: asDouble(j['issuancePaid']),
      );

  final String id;
  final String type;
  final String last4;
  final String expiry;
  final String holder;
  final double balance;
  final bool frozen;
  final String status;
  final double issuancePaid;
}

class CardsData {
  const CardsData({required this.virtual, required this.physical});

  factory CardsData.fromJson(Map<String, dynamic> j) => CardsData(
        virtual: j['virtual'] is Map ? CardInfo.fromJson(asMap(j['virtual'])) : null,
        physical: [for (final c in asMapList(j['physical'])) CardInfo.fromJson(c)],
      );

  final CardInfo? virtual;
  final List<CardInfo> physical;
}

/// Full card number and CVV. Only kept in memory while the user is looking.
class CardDetails {
  const CardDetails({required this.number, required this.cvv, required this.expiry});

  factory CardDetails.fromJson(Map<String, dynamic> j) =>
      CardDetails(number: asStr(j['number']), cvv: asStr(j['cvv']), expiry: asStr(j['expiry']));

  final String number;
  final String cvv;
  final String expiry;

  /// `1234 5678 9012 3456`
  String get spacedNumber {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return [
      for (var i = 0; i < digits.length; i += 4)
        digits.substring(i, i + 4 > digits.length ? digits.length : i + 4),
    ].join(' ');
  }
}

// ---------------------------------------------------------------- catalog

class BillProvider {
  const BillProvider(this.name, this.subtitle);

  factory BillProvider.fromJson(Map<String, dynamic> j) =>
      BillProvider(asStr(j['name']), asStr(j['subtitle']));

  final String name;
  final String subtitle;
}

class DataPlan {
  const DataPlan({required this.id, required this.size, required this.days, required this.price});

  factory DataPlan.fromJson(Map<String, dynamic> j) => DataPlan(
        id: asStr(j['id']),
        size: asStr(j['size']),
        days: asInt(j['days']),
        price: asDouble(j['price']),
      );

  final String id;
  final String size;
  final int days;
  final double price;

  String get validity => '$days days validity';
}

/// A TV or internet package.
class BillPackage {
  const BillPackage({required this.id, required this.name, required this.detail, required this.price});

  factory BillPackage.fromJson(Map<String, dynamic> j) => BillPackage(
        id: asStr(j['id']),
        name: asStr(j['name']),
        detail: asStr(j['detail']),
        price: asDouble(j['price']),
      );

  final String id;
  final String name;
  final String detail;
  final double price;
}

class Fees {
  const Fees({
    this.transfer = 0,
    this.mobileMoneySend = 0,
    this.bill = 0,
    this.cardIssuance = 0,
    this.physicalCard = 0,
    this.terminalDeposit = 0,
    this.terminalDelivery = 0,
    this.cardFundingPercent = 0,
  });

  factory Fees.fromJson(Map<String, dynamic> j) => Fees(
        transfer: asDouble(j['transfer']),
        mobileMoneySend: asDouble(j['mobileMoneySend']),
        bill: asDouble(j['bill']),
        cardIssuance: asDouble(j['cardIssuance']),
        physicalCard: asDouble(j['physicalCard']),
        terminalDeposit: asDouble(j['terminalDeposit']),
        terminalDelivery: asDouble(j['terminalDelivery']),
        cardFundingPercent: asDouble(j['cardFundingPercent']),
      );

  static const Fees zero = Fees();

  final double transfer;
  final double mobileMoneySend;
  final double bill;
  final double cardIssuance;
  final double physicalCard;
  final double terminalDeposit;
  final double terminalDelivery;

  /// Percentage charged on top when adding money by card, for example 1.5.
  final double cardFundingPercent;

  /// Fee in Leones for adding [amount] by card.
  double cardFundingFee(double amount) => (amount * cardFundingPercent).roundToDouble() / 100;
}

class SupportInfo {
  const SupportInfo({required this.phone, required this.email, required this.hours});

  factory SupportInfo.fromJson(Map<String, dynamic> j) =>
      SupportInfo(phone: asStr(j['phone']), email: asStr(j['email']), hours: asStr(j['hours']));

  final String phone;
  final String email;
  final String hours;
}

class Catalog {
  const Catalog({
    required this.banks,
    required this.mobileMoney,
    required this.networks,
    required this.electricity,
    required this.tv,
    required this.internet,
    required this.dataPlans,
    required this.tvPackages,
    required this.internetPackages,
    required this.fees,
    required this.terminalCategories,
    required this.districts,
    required this.topics,
    required this.support,
    this.onlineFunding = false,
  });

  factory Catalog.fromJson(Map<String, dynamic> j) {
    final terminal = asMap(j['terminal']);
    return Catalog(
      banks: asStrList(j['banks']),
      mobileMoney: asStrList(j['mobileMoney']),
      networks: asStrList(j['networks']),
      electricity: [for (final e in asMapList(j['electricity'])) BillProvider.fromJson(e)],
      tv: [for (final e in asMapList(j['tv'])) BillProvider.fromJson(e)],
      internet: [for (final e in asMapList(j['internet'])) BillProvider.fromJson(e)],
      dataPlans: [for (final e in asMapList(j['dataPlans'])) DataPlan.fromJson(e)],
      tvPackages: [for (final e in asMapList(j['tvPackages'])) BillPackage.fromJson(e)],
      internetPackages: [for (final e in asMapList(j['internetPackages'])) BillPackage.fromJson(e)],
      fees: Fees.fromJson(asMap(j['fees'])),
      terminalCategories: asStrList(terminal['categories']),
      districts: asStrList(terminal['districts']),
      topics: asStrList(j['topics']),
      support: SupportInfo.fromJson(asMap(j['support'])),
      onlineFunding: asStr(asMap(j['features'])['fundingMode']) == 'checkout',
    );
  }

  final List<String> banks;
  final List<String> mobileMoney;
  final List<String> networks;
  final List<BillProvider> electricity;
  final List<BillProvider> tv;
  final List<BillProvider> internet;
  final List<DataPlan> dataPlans;
  final List<BillPackage> tvPackages;
  final List<BillPackage> internetPackages;
  final Fees fees;
  final List<String> terminalCategories;
  final List<String> districts;
  final List<String> topics;
  final SupportInfo support;

  /// True on a live server: money is added on the provider's secure page (card, bank, mobile money).
  final bool onlineFunding;
}

// ---------------------------------------------------------------- lookups

class MeterInfo {
  const MeterInfo(this.name, this.address);

  factory MeterInfo.fromJson(Map<String, dynamic> j) =>
      MeterInfo(asStr(j['customerName']), asStr(j['address']));

  final String name;
  final String address;
}

class TrustPayUser {
  const TrustPayUser({required this.fullName, required this.accountNumber});

  factory TrustPayUser.fromJson(Map<String, dynamic> j) =>
      TrustPayUser(fullName: asStr(j['fullName']), accountNumber: asStr(j['accountNumber']));

  final String fullName;
  final String accountNumber;
}

class Recipient {
  const Recipient({
    required this.id,
    required this.bank,
    required this.accountNumber,
    required this.accountName,
  });

  factory Recipient.fromJson(Map<String, dynamic> j) => Recipient(
        id: asStr(j['id'] ?? j['_id']),
        bank: asStr(j['bank']),
        accountNumber: asStr(j['accountNumber']),
        accountName: asStr(j['accountName']),
      );

  final String id;
  final String bank;
  final String accountNumber;
  final String accountName;
}

// ------------------------------------------------------------------ drafts

class TransferDraft {
  const TransferDraft({
    required this.bank,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.fee,
    this.note = '',
    this.saveRecipient = false,
  });

  final String bank;
  final String accountNumber;
  final String accountName;
  final double amount;

  /// From `catalog.fees.transfer`.
  final double fee;
  final String note;
  final bool saveRecipient;

  double get total => amount + fee;

  String get maskedAccount => accountNumber.length <= 4
      ? accountNumber
      : '•• ${accountNumber.substring(accountNumber.length - 4)}';
}

class BillDraft {
  const BillDraft({
    required this.provider,
    required this.prepaid,
    required this.meter,
    required this.customer,
    required this.amount,
    required this.phone,
    required this.fee,
  });

  final String provider;
  final bool prepaid;
  final String meter;
  final String customer;
  final double amount;
  final String phone;

  /// From `catalog.fees.bill`.
  final double fee;

  double get total => amount + fee;

  String get typeLabel => prepaid ? 'Prepaid' : 'Postpaid';
}

class TerminalDraft {
  const TerminalDraft({
    required this.businessName,
    required this.category,
    required this.address,
    required this.city,
    required this.state,
    required this.contact,
    required this.deposit,
    required this.deliveryFee,
  });

  final String businessName;
  final String category;
  final String address;
  final String city;
  final String state;
  final String contact;

  /// From `catalog.fees.terminalDeposit` and `terminalDelivery`.
  final double deposit;
  final double deliveryFee;

  double get total => deposit + deliveryFee;
}

// -------------------------------------------------------------------- POS

class PosTerminal {
  const PosTerminal({
    required this.id,
    required this.code,
    required this.serial,
    required this.status,
    required this.lastSync,
    required this.location,
    required this.connection,
    required this.battery,
  });

  factory PosTerminal.fromJson(Map<String, dynamic> j) => PosTerminal(
        id: asStr(j['id'] ?? j['_id']),
        code: asStr(j['code']),
        serial: asStr(j['serial']),
        status: asStr(j['status'], 'active'),
        lastSync: tryParseDate(j['lastSync']),
        location: asStr(j['location']),
        connection: asStr(j['connection']),
        battery: j['battery'] == null ? null : asInt(j['battery'].toString().replaceAll('%', ''), -1),
      );

  final String id;
  final String code;
  final String serial;

  /// `active` or `disabled`.
  final String status;
  final DateTime? lastSync;
  final String location;
  final String connection;
  final int? battery;

  bool get enabled => status == 'active';
}

class PosRecent {
  const PosRecent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
    required this.createdAt,
  });

  factory PosRecent.fromJson(Map<String, dynamic> j) => PosRecent(
        id: asStr(j['id'] ?? j['_id']),
        title: asStr(j['title']),
        subtitle: asStr(j['subtitle']),
        amount: asDouble(j['amount']),
        kind: asStr(j['kind']),
        createdAt: tryParseDate(j['createdAt']),
      );

  final String id;
  final String title;
  final String subtitle;
  final double amount;

  /// `card` or `transfer`.
  final String kind;
  final DateTime? createdAt;
}

class SettlementPayment {
  const SettlementPayment({
    required this.reference,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  factory SettlementPayment.fromJson(Map<String, dynamic> j) => SettlementPayment(
        reference: asStr(j['reference']),
        title: asStr(j['title']),
        subtitle: asStr(j['subtitle']),
        amount: asDouble(j['amount']),
      );

  final String reference;
  final String title;
  final String subtitle;
  final double amount;
}

class Settlement {
  const Settlement({
    required this.id,
    required this.reference,
    required this.net,
    required this.gross,
    required this.fees,
    required this.count,
    required this.scheduledFor,
    required this.status,
    required this.destination,
    required this.payments,
  });

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
        id: asStr(j['id'] ?? j['_id']),
        reference: asStr(j['reference']),
        net: asDouble(j['net']),
        gross: asDouble(j['gross']),
        fees: asDouble(j['fees']),
        count: asInt(j['count']),
        scheduledFor: tryParseDate(j['scheduledFor']),
        status: asStr(j['status']),
        destination: asStr(j['destination']),
        payments: [for (final p in asMapList(j['payments'])) SettlementPayment.fromJson(p)],
      );

  final String id;
  final String reference;
  final double net;
  final double gross;
  final double fees;
  final int count;
  final DateTime? scheduledFor;
  final String status;
  final String destination;
  final List<SettlementPayment> payments;
}

class SettlementData {
  const SettlementData({required this.settlement, required this.rolledAmount, required this.rolledCount});

  factory SettlementData.fromJson(Map<String, dynamic> j) {
    final rolled = asMap(j['rolledOver']);
    return SettlementData(
      settlement: j['settlement'] is Map ? Settlement.fromJson(asMap(j['settlement'])) : null,
      rolledAmount: asDouble(rolled['amount']),
      rolledCount: asInt(rolled['count']),
    );
  }

  final Settlement? settlement;
  final double rolledAmount;
  final int rolledCount;
}

class PosRequest {
  const PosRequest({
    required this.id,
    required this.reference,
    required this.status,
    required this.createdAt,
    required this.expectedFrom,
    required this.expectedTo,
  });

  factory PosRequest.fromJson(Map<String, dynamic> j) => PosRequest(
        id: asStr(j['id'] ?? j['_id']),
        reference: asStr(j['reference']),
        status: asStr(j['status']),
        createdAt: tryParseDate(j['createdAt']),
        expectedFrom: tryParseDate(j['expectedFrom']),
        expectedTo: tryParseDate(j['expectedTo']),
      );

  final String id;
  final String reference;
  final String status;
  final DateTime? createdAt;
  final DateTime? expectedFrom;
  final DateTime? expectedTo;
}

class PosOverview {
  const PosOverview({
    required this.businessName,
    required this.terminal,
    required this.todayCollected,
    required this.todayCount,
    required this.nextSettlement,
    required this.recent,
    required this.request,
    this.settlementAccount,
    this.merchantCode = '',
  });

  factory PosOverview.fromJson(Map<String, dynamic> j) {
    final today = asMap(j['today']);
    return PosOverview(
      businessName: asStr(j['businessName']),
      terminal: j['terminal'] is Map ? PosTerminal.fromJson(asMap(j['terminal'])) : null,
      todayCollected: asDouble(today['collected']),
      todayCount: asInt(today['count']),
      nextSettlement: j['nextSettlement'] is Map ? Settlement.fromJson(asMap(j['nextSettlement'])) : null,
      recent: [for (final r in asMapList(j['recent'])) PosRecent.fromJson(r)],
      request: j['request'] is Map ? PosRequest.fromJson(asMap(j['request'])) : null,
      settlementAccount: j['settlementAccount'] is Map ? asMap(j['settlementAccount']) : null,
      merchantCode: asStr(j['merchantCode']),
    );
  }

  /// Linked bank account `{bank, accountName, accountNumber (masked), payToBank}` or null.
  final Map<String, dynamic>? settlementAccount;
  final String merchantCode;
  final String businessName;
  final PosTerminal? terminal;
  final double todayCollected;
  final int todayCount;
  final Settlement? nextSettlement;
  final List<PosRecent> recent;
  final PosRequest? request;
}

// ---------------------------------------------------------------- support

class ChatMessage {
  const ChatMessage({required this.id, required this.fromUser, required this.text, required this.createdAt});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: asStr(j['id'] ?? j['_id']),
        fromUser: asStr(j['from']) == 'user',
        text: asStr(j['text']),
        createdAt: parseDate(j['createdAt']),
      );

  final String id;

  /// True for the customer's own messages, false for an agent.
  final bool fromUser;
  final String text;
  final DateTime createdAt;
}

class Ticket {
  const Ticket({
    required this.id,
    required this.reference,
    required this.topic,
    required this.status,
    required this.createdAt,
    required this.lastMessage,
    required this.customer,
    required this.messages,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) {
    final last = j['lastMessage'];
    final user = j['user'];
    return Ticket(
      id: asStr(j['id'] ?? j['_id']),
      reference: asStr(j['reference']),
      topic: asStr(j['topic']),
      status: asStr(j['status']),
      createdAt: tryParseDate(j['createdAt']),
      lastMessage: last is Map ? asStrOrNull(last['text']) : asStrOrNull(last),
      customer: user is Map
          ? asStrOrNull(user['fullName'] ?? user['name'])
          : asStrOrNull(j['userName'] ?? j['customer'] ?? j['user']),
      messages: [for (final m in asMapList(j['messages'])) ChatMessage.fromJson(m)],
    );
  }

  final String id;
  final String reference;
  final String topic;

  /// For example `open` or `closed`.
  final String status;
  final DateTime? createdAt;
  final String? lastMessage;

  /// Staff view only, when the server includes it.
  final String? customer;

  /// Only filled by endpoints that return the conversation.
  final List<ChatMessage> messages;

  bool get isOpen => status.toLowerCase() != 'closed' && status.toLowerCase() != 'resolved';
}

class TicketThread {
  const TicketThread({required this.ticket, required this.messages});

  factory TicketThread.fromJson(Map<String, dynamic> j) => TicketThread(
        ticket: Ticket.fromJson(asMap(j['ticket'])),
        messages: [for (final m in asMapList(j['messages'])) ChatMessage.fromJson(m)],
      );

  final Ticket ticket;
  final List<ChatMessage> messages;
}

// ------------------------------------------------------------------ admin

class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.activeToday,
    required this.pendingApprovals,
    required this.openTickets,
    required this.volumeToday,
    required this.volumeYesterday,
    required this.changePct,
    required this.week,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: asInt(j['totalUsers']),
        activeToday: asInt(j['activeToday']),
        pendingApprovals: asInt(j['pendingApprovals']),
        openTickets: asInt(j['openTickets']),
        volumeToday: asDouble(j['volumeToday']),
        volumeYesterday: asDouble(j['volumeYesterday']),
        changePct: asDouble(j['changePct']),
        week: [for (final w in asMapList(j['week'])) (asStr(w['label']), asDouble(w['value']))],
      );

  final int totalUsers;
  final int activeToday;
  final int pendingApprovals;
  final int openTickets;
  final double volumeToday;
  final double volumeYesterday;
  final double changePct;
  final List<(String, double)> week;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.tier,
    required this.status,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: asStr(j['id'] ?? j['_id']),
        name: asStr(j['name'] ?? j['fullName']),
        phone: asStr(j['phone']),
        tier: asStr(j['tier']),
        status: asStr(j['status'], 'active'),
      );

  final String id;
  final String name;
  final String phone;
  final String tier;

  /// `active`, `suspended` or `pending_kyc`.
  final String status;

  String get statusLabel => switch (status) {
        'active' => 'Active',
        'suspended' => 'Suspended',
        'pending_kyc' => 'Pending KYC',
        _ => status,
      };

  AdminUser copyWith({String? status}) => AdminUser(
        id: id,
        name: name,
        phone: phone,
        tier: tier,
        status: status ?? this.status,
      );
}

class Approval {
  const Approval({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  factory Approval.fromJson(Map<String, dynamic> j) => Approval(
        id: asStr(j['id'] ?? j['_id']),
        type: asStr(j['type']),
        title: asStr(j['title']),
        detail: asStr(j['detail']),
        createdAt: tryParseDate(j['createdAt']),
      );

  final String id;

  /// `kyc`, `pos` or `limit`.
  final String type;
  final String title;
  final String detail;
  final DateTime? createdAt;
}

// ------------------------------------------------------------------- auth

/// Answer of sign up and login.
class AuthResult {
  const AuthResult({required this.token, required this.user, this.devOtp});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: asStr(j['token']),
        user: User.fromJson(asMap(j['user'])),
        devOtp: asStrOrNull(j['devOtp']),
      );

  final String token;
  final User user;

  /// Only present on a sandbox server with OTP_DEBUG=true. Never present in live mode.
  final String? devOtp;
}
