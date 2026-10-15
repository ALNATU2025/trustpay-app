import '../models/models.dart';
import 'api.dart';

/// Typed calls to the TrustPay backend (`trustpay-backend`, see its API.md).
///
/// Every money-moving call takes an `idempotencyKey`. Create ONE key per user action with
/// [newIdempotencyKey] (for example in the confirm screen's `initState`) and reuse it on retries,
/// so a dropped connection can never charge the customer twice.
class TrustPayApi {
  TrustPayApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query}) async =>
      asMap(await _c.get(path, query: query));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
          {bool auth = true, String? key}) async =>
      asMap(await _c.post(path, body: body, auth: auth, idempotencyKey: key));

  Future<PaymentResult> _pay(String path, Map<String, dynamic> body, String key) async =>
      PaymentResult.fromJson(await _post(path, body, key: key));

  /// Runs a lookup and turns "404 not found" into null.
  Future<T?> _lookup<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  // ---------------------------------------------------------------- catalog

  Future<Catalog> catalog() async => Catalog.fromJson(await _get('/catalog'));

  // ------------------------------------------------------------------- auth

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async =>
      AuthResult.fromJson(await _post(
        '/auth/register',
        {'firstName': firstName, 'lastName': lastName, 'email': email, 'phone': phone, 'password': password},
        auth: false,
      ));

  Future<AuthResult> login(String identifier, String password) async =>
      AuthResult.fromJson(await _post('/auth/login', {'identifier': identifier, 'password': password}, auth: false));

  /// Sends a new phone code. Returns the code only on a sandbox server (OTP_DEBUG).
  Future<String?> sendOtp() async => asStrOrNull((await _post('/auth/otp/send', {}))['devOtp']);

  Future<User> verifyOtp(String code) async => User.fromJson(asMap((await _post('/auth/otp/verify', {'code': code}))['user']));

  Future<User> submitIdentity({
    required String legalName,
    required DateTime dob,
    required String idType,
    required String idNumber,
    required String address,
  }) async =>
      User.fromJson(asMap((await _post('/auth/identity', {
        'legalName': legalName,
        'dob': dob.toIso8601String().substring(0, 10),
        'idType': idType,
        'idNumber': idNumber,
        'address': address,
      }))['user']));

  Future<User> setPin(String pin) async => User.fromJson(asMap((await _post('/auth/pin', {'pin': pin}))['user']));

  Future<void> logout() async {
    await _post('/auth/logout', {});
  }

  /// Returns the reset code only on a sandbox server (OTP_DEBUG).
  Future<String?> forgotPassword(String identifier) async =>
      asStrOrNull((await _post('/auth/forgot', {'identifier': identifier}, auth: false))['devCode']);

  Future<String> verifyResetCode(String identifier, String code) async =>
      asStr((await _post('/auth/forgot/verify', {'identifier': identifier, 'code': code}, auth: false))['resetToken']);

  Future<void> resetPassword(String resetToken, String password) async {
    await _post('/auth/reset', {'resetToken': resetToken, 'password': password}, auth: false);
  }

  // --------------------------------------------------------------------- me

  Future<User> me() async => User.fromJson(asMap((await _get('/me'))['user']));

  Future<User> updateProfile({String? firstName, String? lastName, String? email, String? address, String? businessName}) async {
    final res = asMap(await _c.patch('/me', body: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (businessName != null) 'businessName': businessName,
    }));
    return User.fromJson(asMap(res['user']));
  }

  /// Changing the password signs other devices out; the server returns a fresh token for this one.
  Future<void> changePassword(String current, String next) async {
    final res = await _post('/me/password', {'currentPassword': current, 'newPassword': next});
    final token = asStrOrNull(res['token']);
    if (token != null) await _c.setToken(token);
  }

  Future<void> changePin(String current, String next) async {
    await _post('/me/pin', {'currentPin': current, 'newPin': next});
  }

  Future<void> verifyPin(String pin) async {
    await _post('/me/pin/verify', {'pin': pin});
  }

  Future<void> requestLimitIncrease([String? reason]) async {
    await _post('/me/limit-request', {if (reason != null && reason.isNotEmpty) 'reason': reason});
  }

  // ----------------------------------------------------------------- history

  Future<PagedList<Txn>> transactions({
    int page = 1,
    int limit = 20,
    String service = 'all',
    String? status,
    String? q,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _get('/transactions', query: {
      'page': page,
      'limit': limit,
      'service': service,
      'status': status,
      'q': q,
      'from': from?.toUtc().toIso8601String(),
      'to': to?.toUtc().toIso8601String(),
    });
    return PagedList([for (final t in asMapList(res['items'])) Txn.fromJson(t)], asInt(res['page'], page), asBool(res['hasMore']));
  }

  Future<Txn> transaction(String id) async => Txn.fromJson(asMap((await _get('/transactions/$id'))['transaction']));

  Future<List<Recipient>> recipients() async =>
      [for (final r in asMapList((await _get('/recipients'))['items'])) Recipient.fromJson(r)];

  Future<void> deleteRecipient(String id) async {
    await _c.request('DELETE', '/recipients/$id');
  }

  // ----------------------------------------------------------------- lookups

  /// Account holder name, or null when the account does not exist.
  Future<String?> lookupBankAccount(String bank, String accountNumber) => _lookup(
      () async => asStr((await _post('/lookup/bank', {'bank': bank, 'accountNumber': accountNumber}))['accountName']));

  Future<MeterInfo?> lookupMeter(String provider, String meter) =>
      _lookup(() async => MeterInfo.fromJson(await _post('/lookup/meter', {'provider': provider, 'meter': meter})));

  /// TV or internet customer name. [category] is `tv` or `internet`.
  Future<String?> lookupCustomer(String category, String provider, String number) => _lookup(() async =>
      asStr((await _post('/lookup/customer', {'category': category, 'provider': provider, 'number': number}))['customerName']));

  /// Finds a TrustPay customer by 10-digit account number or by phone.
  Future<TrustPayUser?> lookupUser({String? accountNumber, String? phone}) => _lookup(() async => TrustPayUser.fromJson(await _post(
      '/lookup/user', {if (accountNumber != null) 'accountNumber': accountNumber, if (phone != null) 'phone': phone})));

  /// Mobile money wallet holder name, or null.
  Future<String?> lookupWallet(String provider, String number) => _lookup(
      () async => asStr((await _post('/lookup/wallet', {'provider': provider, 'number': number}))['holderName']));

  // ---------------------------------------------------------------- payments

  Future<PaymentResult> transferBank({
    required String bank,
    required String accountNumber,
    required String accountName,
    required double amount,
    String note = '',
    bool saveRecipient = false,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/transfer/bank', {
        'bank': bank,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'amount': amount,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'saveRecipient': saveRecipient,
        'pin': pin,
      }, idempotencyKey);

  Future<PaymentResult> transferUser({
    required String accountNumber,
    required double amount,
    String note = '',
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/transfer/user', {
        'accountNumber': accountNumber,
        'amount': amount,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'pin': pin,
      }, idempotencyKey);

  Future<PaymentResult> mobileMoneySend({
    required String provider,
    required String number,
    required double amount,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/mobile-money/send', {'provider': provider, 'number': number, 'amount': amount, 'pin': pin}, idempotencyKey);

  /// Adds money from a mobile money wallet using the 6-digit approval code.
  Future<PaymentResult> mobileMoneyAdd({
    required String provider,
    required String number,
    required double amount,
    required String code,
    required String idempotencyKey,
  }) =>
      _pay('/payments/mobile-money/add', {'provider': provider, 'number': number, 'amount': amount, 'code': code}, idempotencyKey);

  /// Adds money by card. The app never sends the full card number: only the last 4 digits and the brand.
  Future<PaymentResult> fundByCard({
    required double amount,
    required String cardLast4,
    required String brand,
    required String idempotencyKey,
  }) =>
      _pay('/payments/funding/card', {'amount': amount, 'cardLast4': cardLast4, 'brand': brand}, idempotencyKey);

  /// Starts an online top-up. On a live server the result has a `checkoutUrl` to open (card, bank or
  /// mobile money are paid on the provider's page and the balance rises when it confirms).
  /// On a sandbox server the money is added at once and the url is null.
  Future<(PaymentResult, String?)> startCheckout({required double amount, required String idempotencyKey}) async {
    final json = await _post('/payments/funding/checkout', {'amount': amount}, key: idempotencyKey);
    return (PaymentResult.fromJson(json), asStrOrNull(json['checkoutUrl']));
  }

  /// Starts a mobile money top-up. Live: returns the USSD code to dial and the balance rises when the
  /// provider confirms. Test server: the money is added at once and the code is null.
  Future<(PaymentResult, String?, DateTime?)> startMomoTopUp({
    required String provider,
    required String number,
    required double amount,
    required String idempotencyKey,
  }) async {
    final json = await _post('/payments/funding/momo-code', {'provider': provider, 'number': number, 'amount': amount}, key: idempotencyKey);
    final exp = asStrOrNull(json['expiresAt']);
    return (PaymentResult.fromJson(json), asStrOrNull(json['ussdCode']), exp == null ? null : DateTime.tryParse(exp)?.toLocal());
  }

  Future<PaymentResult> payElectricity({
    required String provider,
    required bool prepaid,
    required String meter,
    String customer = '',
    required double amount,
    required String phone,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/bills', {
        'category': 'electricity',
        'provider': provider,
        'prepaid': prepaid,
        'meter': meter,
        if (customer.isNotEmpty) 'customer': customer,
        'amount': amount,
        'phone': phone,
        'pin': pin,
      }, idempotencyKey);

  /// TV or internet package. The price comes from the server's package list, not from the app.
  Future<PaymentResult> paySubscription({
    required String category,
    required String provider,
    required String accountNumber,
    required String packageId,
    required String phone,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/subscription', {
        'category': category,
        'provider': provider,
        'accountNumber': accountNumber,
        'packageId': packageId,
        'phone': phone,
        'pin': pin,
      }, idempotencyKey);

  Future<PaymentResult> buyAirtime({
    required String network,
    required String phone,
    required double amount,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/airtime', {'network': network, 'phone': phone, 'amount': amount, 'pin': pin}, idempotencyKey);

  Future<PaymentResult> buyData({
    required String network,
    required String phone,
    required String planId,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/data', {'network': network, 'phone': phone, 'planId': planId, 'pin': pin}, idempotencyKey);

  // ------------------------------------------------------------------- cards

  Future<CardsData> cards() async => CardsData.fromJson(await _get('/cards'));

  /// Creates the virtual card and loads [amount] onto it (may be 0). Result has `.card`.
  Future<PaymentResult> createVirtualCard({required double amount, required String pin, required String idempotencyKey}) =>
      _pay('/cards/virtual', {'amount': amount, 'pin': pin}, idempotencyKey);

  Future<PaymentResult> fundVirtualCard({required double amount, required String pin, required String idempotencyKey}) =>
      _pay('/cards/virtual/fund', {'amount': amount, 'pin': pin}, idempotencyKey);

  /// Full number and CVV, after the PIN. Keep them in memory only while shown.
  Future<CardDetails> revealVirtualCard(String pin) async => CardDetails.fromJson(await _post('/cards/virtual/details', {'pin': pin}));

  Future<CardInfo> freezeVirtualCard(bool frozen) async =>
      CardInfo.fromJson(asMap((await _post('/cards/virtual/freeze', {'frozen': frozen}))['card']));

  /// Orders the physical card. Result has `.card` (status pending) and `.request`.
  Future<PaymentResult> orderPhysicalCard({
    required String name,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/cards/physical', {'name': name, 'phone': phone, 'address': address, 'city': city, 'state': state, 'pin': pin}, idempotencyKey);

  // --------------------------------------------------------------------- POS

  Future<PosOverview> posOverview() async => PosOverview.fromJson(await _get('/pos/overview'));

  /// Phone POS: asks a customer to pay by mobile money. Returns the charge (status Pending + ussdCode).
  Future<Map<String, dynamic>> createPosCharge({
    required double amount,
    required String number,
    required String provider,
    String note = '',
    required String idempotencyKey,
  }) async =>
      asMap((await _post('/pos/charges', {
        'amount': amount,
        'number': number,
        if (provider.isNotEmpty) 'provider': provider,
        if (note.isNotEmpty) 'note': note,
      }, key: idempotencyKey))['charge']);

  /// Links (or replaces) the merchant's bank account. The server verifies the name with the bank.
  Future<Map<String, dynamic>?> linkSettlementAccount({
    required String bank,
    required String accountNumber,
    required bool payToBank,
    required String pin,
  }) async {
    final r = await _post('/pos/settlement-account', {'bank': bank, 'accountNumber': accountNumber, 'payToBank': payToBank, 'pin': pin});
    final a = r['account'];
    return a is Map ? asMap(a) : null;
  }

  Future<Map<String, dynamic>?> setSettlementTarget({required bool payToBank, required String pin}) async {
    final a = (await _post('/pos/settlement-account/target', {'payToBank': payToBank, 'pin': pin}))['account'];
    return a is Map ? asMap(a) : null;
  }

  Future<void> unlinkSettlementAccount(String pin) async {
    await _post('/pos/settlement-account/unlink', {'pin': pin});
  }

  /// The merchant's permanent code, business name and QR payload.
  Future<Map<String, dynamic>> posCode() async => _get('/pos/code');

  /// Merchant name for a 6-digit code, or null when there is none.
  Future<String?> lookupMerchant(String code) => _lookup(() async => asStr((await _post('/lookup/merchant', {'code': code}))['name']));

  Future<PaymentResult> payMerchant({
    required String code,
    required double amount,
    String note = '',
    required String pin,
    required String idempotencyKey,
  }) =>
      _pay('/payments/pos/pay', {
        'code': code,
        'amount': amount,
        if (note.isNotEmpty) 'note': note,
        'pin': pin,
      }, idempotencyKey);

  Future<Map<String, dynamic>> posCharge(String id) async => asMap((await _get('/pos/charges/$id'))['charge']);

  Future<SettlementData> nextSettlement() async => SettlementData.fromJson(await _get('/pos/settlements/next'));

  Future<Settlement> settlement(String id) async => Settlement.fromJson(asMap((await _get('/pos/settlements/$id'))['settlement']));

  Future<PosTerminal> setTerminalEnabled(bool enabled) async =>
      PosTerminal.fromJson(asMap((await _post('/pos/terminal/toggle', {'enabled': enabled}))['terminal']));

  /// Requests a terminal and charges deposit plus delivery. Result has `.request`.
  Future<PaymentResult> requestTerminal(TerminalDraft d, {required String pin, required String idempotencyKey}) =>
      _pay('/pos/terminal/request', {
        'businessName': d.businessName,
        'category': d.category,
        'address': d.address,
        'city': d.city,
        'state': d.state,
        'contact': d.contact,
        'pin': pin,
      }, idempotencyKey);

  // ----------------------------------------------------------------- support

  Future<List<Ticket>> tickets() async => [for (final t in asMapList((await _get('/support/tickets'))['items'])) Ticket.fromJson(t)];

  Future<TicketThread> createTicket(String topic, String message) async =>
      TicketThread.fromJson(await _post('/support/tickets', {'topic': topic, 'message': message}));

  Future<TicketThread> ticketThread(String id) async => TicketThread.fromJson(await _get('/support/tickets/$id'));

  Future<ChatMessage> sendTicketMessage(String id, String text) async =>
      ChatMessage.fromJson(asMap((await _post('/support/tickets/$id/messages', {'text': text}))['message']));

  /// The customer's live chat (created with a greeting from an agent on first use).
  Future<TicketThread> chat() async => TicketThread.fromJson(await _get('/support/chat'));

  Future<ChatMessage> sendChat(String text) async =>
      ChatMessage.fromJson(asMap((await _post('/support/chat', {'text': text}))['message']));

  // ------------------------------------------------------------------- admin

  Future<AdminStats> adminStats() async => AdminStats.fromJson(await _get('/admin/stats'));

  Future<PagedList<AdminUser>> adminUsers({String? q, int page = 1}) async {
    final res = await _get('/admin/users', query: {'q': q, 'page': page, 'limit': 30});
    return PagedList([for (final u in asMapList(res['items'])) AdminUser.fromJson(u)], asInt(res['page'], page), asBool(res['hasMore']));
  }

  Future<AdminUser> setUserStatus(String id, String status) async =>
      AdminUser.fromJson(asMap((await _c.patch('/admin/users/$id', body: {'status': status}))['user']));

  PagedList<Map<String, dynamic>> _paged(Map<String, dynamic> res, int page) =>
      PagedList(asMapList(res['items']), asInt(res['page'], page), asBool(res['hasMore']));

  /// Every transaction on the platform. [service]: all|transfer|bill|airtime|funding.
  Future<PagedList<Map<String, dynamic>>> adminTransactions({
    String service = 'all',
    String? status,
    String? direction,
    String? userId,
    String? q,
    bool review = false,
    int page = 1,
  }) async =>
      _paged(
        await _get('/admin/transactions', query: {
          'service': service,
          'status': status,
          'direction': direction,
          'user': userId,
          'q': q,
          'review': review ? '1' : null,
          'page': page,
          'limit': 30,
        }),
        page,
      );

  Future<Map<String, dynamic>> adminUserDetail(String id) async => _get('/admin/users/$id');

  Future<void> adminUnlockUser(String id) async {
    await _post('/admin/users/$id/unlock', {});
  }

  /// Manual credit/debit. [type] is `credit` or `debit`; [key] makes a retry safe.
  Future<Map<String, dynamic>> adminAdjustBalance(
    String id, {
    required String type,
    required double amount,
    required String reason,
    required String key,
  }) async =>
      _post('/admin/users/$id/funding', {'type': type, 'amount': amount, 'reason': reason, 'key': key});

  Future<Map<String, dynamic>> adminPosOverview() async => _get('/admin/pos/overview');

  Future<PagedList<Map<String, dynamic>>> adminPosList(String what, {String? ownerId, String? q, int page = 1}) async =>
      _paged(await _get('/admin/pos/$what', query: {'owner': ownerId, 'q': q, 'page': page, 'limit': 30}), page);

  Future<List<Approval>> adminApprovals() async =>
      [for (final a in asMapList((await _get('/admin/approvals'))['items'])) Approval.fromJson(a)];

  Future<void> decideApproval(String id, {required bool approve, String? reason}) async {
    await _post('/admin/approvals/$id/decision', {'approve': approve, if (reason != null && reason.isNotEmpty) 'reason': reason});
  }

  /// [status] is `open` or `closed`.
  Future<PagedList<Ticket>> adminTickets({String? status, int page = 1}) async {
    final res = await _get('/admin/tickets', query: {'status': status, 'page': page, 'limit': 30});
    return PagedList([for (final t in asMapList(res['items'])) Ticket.fromJson(t)], asInt(res['page'], page), asBool(res['hasMore']));
  }

  Future<TicketThread> adminTicket(String id) async => TicketThread.fromJson(await _get('/admin/tickets/$id'));

  Future<ChatMessage> adminReply(String id, String text) async =>
      ChatMessage.fromJson(asMap((await _post('/admin/tickets/$id/reply', {'text': text}))['message']));

  Future<void> adminCloseTicket(String id) async {
    await _post('/admin/tickets/$id/close', {});
  }
}

/// The app-wide API.
final TrustPayApi api = TrustPayApi(apiClient);
