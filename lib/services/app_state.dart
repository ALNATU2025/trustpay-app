import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api.dart';
import 'trustpay_api.dart';

/// Where the app should go after it starts.
class StartTarget {
  const StartTarget(this.route, {this.arguments});

  final String route;
  final Object? arguments;
}

/// The signed-in customer, their balance and the server's catalog. Screens read from here and
/// rebuild with `ListenableBuilder(listenable: appState, ...)`. There is no mock data: until the
/// server answers, [user] and [catalog] are null.
class AppState extends ChangeNotifier {
  User? _user;
  Catalog? _catalog;
  int _txnVersion = 0;
  Object? _catalogError;

  /// A sandbox server (OTP_DEBUG) returns the code in the response so the app can be tested
  /// without SMS. Always null against a live server.
  String? devOtp;

  User? get user => _user;

  /// The signed-in customer. Only call on screens that need a login.
  User get me => _user!;

  Catalog? get catalog => _catalog;

  /// The catalog. Only call on screens inside the app shell, which waits for it to load.
  Catalog get cat => _catalog!;

  Object? get catalogError => _catalogError;

  bool get signedIn => _user != null;
  double get balance => _user?.balance ?? 0;
  bool get isAdmin => _user?.isStaff ?? false;

  /// Goes up after every payment, so lists of transactions know to reload.
  int get txnVersion => _txnVersion;

  /// Wakes the server and reads the saved session. Returns where to go first.
  Future<StartTarget> bootstrap() async {
    apiClient.onSessionExpired = reset;
    final token = await apiClient.loadToken();
    if (token == null || token.isEmpty) return const StartTarget('/intro');
    try {
      final user = await api.me();
      _user = user;
      notifyListeners();
      return routeFor(user);
    } on ApiException catch (e) {
      // 401 already cleared the token and reset state. A network problem keeps the token.
      if (e.status == 401) return const StartTarget('/intro');
      return const StartTarget('/login');
    }
  }

  /// The screen for the next unfinished sign-up step, or Home when sign-up is complete.
  static StartTarget routeFor(User user) => switch (user.onboardingStep) {
        'phone' => StartTarget('/otp', arguments: user.phone),
        'identity' => const StartTarget('/identity'),
        'pin' => const StartTarget('/ready'),
        _ => const StartTarget('/home'),
      };

  Future<void> loadCatalog({bool force = false}) async {
    if (_catalog != null && !force) return;
    try {
      _catalog = await api.catalog();
      _catalogError = null;
    } catch (e) {
      _catalogError = e;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Saves the session from a sign up or login.
  Future<void> signIn(AuthResult result) async {
    await apiClient.setToken(result.token);
    _user = result.user;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Re-reads the customer (balance, status). Errors are ignored: the old values stay.
  Future<void> refreshUser() async {
    try {
      _user = await api.me();
      notifyListeners();
    } on ApiException {
      // Keep what we have; the next call will report a real problem.
    }
  }

  /// Applies the new balance from a payment and tells history screens to reload.
  void applyPayment(PaymentResult result) {
    final u = _user;
    if (u != null) _user = u.copyWith(balance: result.balance);
    _txnVersion++;
    notifyListeners();
  }

  /// Signs out on the server (best effort), forgets the token and the in-memory data.
  Future<void> signOut() async {
    try {
      if (apiClient.hasToken) await api.logout();
    } catch (_) {
      // Signing out locally is what matters.
    }
    await apiClient.clearToken();
    reset();
  }

  /// Clears everything held in memory (also used when the server says the session ended).
  void reset() {
    _user = null;
    _txnVersion++;
    notifyListeners();
  }
}

final AppState appState = AppState();
