import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/keys.dart';

/// Base URL of the TrustPay backend. Override at build time:
/// `flutter run --dart-define=API_BASE_URL=https://<service>.onrender.com/api`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://trustpay-backend-zkiv.onrender.com/api',
);

/// An error answer from the server, or a network problem (status 0).
class ApiException implements Exception {
  const ApiException(this.status, this.message, [this.code]);

  /// HTTP status, or 0 when the server could not be reached.
  final int status;

  /// Human readable text that is safe to show to the user.
  final String message;

  /// Machine code such as `BAD_PIN`, `PIN_LOCKED` or `INSUFFICIENT_FUNDS`.
  final String? code;

  bool get isNetwork => status == 0;
  bool get isBadPin => code == 'BAD_PIN' || code == 'PIN_LOCKED';

  @override
  String toString() => message;
}

/// Text to show for any error thrown by an API call.
String errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}

/// A random id for the `Idempotency-Key` header, such as
/// `3f2a9c1e-5b7d-4e0a-9a41-0c8d2b6e7f13`. Create one per user action.
String newIdempotencyKey() {
  final r = math.Random.secure();
  String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

/// Small JSON-over-HTTP client with a bearer token, timeouts, one retry for
/// GETs and a friendly message while a sleeping server wakes up.
///
/// It never logs request or response bodies, because they can contain PINs,
/// passwords, tokens and card numbers.
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  static const Duration timeout = Duration(seconds: 30);

  /// After this long without an answer we tell the user the server is waking up.
  static const Duration slowAfter = Duration(seconds: 6);

  static const String _tokenKey = 'tp_token';

  final http.Client _http;
  String? _token;

  /// Set for the next request only: the customer confirmed a payment that looked like a duplicate.
  bool confirmDuplicateNext = false;
  bool _tokenLoaded = false;
  bool _handlingUnauthorized = false;
  int _slowRequests = 0;

  /// Called when the server says the session is no longer valid (401), after
  /// the token has been cleared. The app uses it to wipe its in-memory state.
  VoidCallback? onSessionExpired;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  // ------------------------------------------------------------- token

  /// Reads the saved token (once) and returns it.
  Future<String?> loadToken() async {
    if (_tokenLoaded) return _token;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
    } catch (_) {
      // Storage can be unavailable. The session then lasts until the app closes.
    }
    _tokenLoaded = true;
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    _tokenLoaded = true;
    _handlingUnauthorized = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  Future<void> clearToken() async {
    _token = null;
    _tokenLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  // ----------------------------------------------------------- requests

  /// Wakes a sleeping server (Render free tier) without waiting for the answer.
  Future<void> warmUp() async {
    try {
      await _http.get(_uri('/health')).timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    String? idempotencyKey,
    bool? retry,
  }) =>
      request('POST', path, body: body ?? const <String, dynamic>{}, auth: auth, idempotencyKey: idempotencyKey, retry: retry);

  Future<dynamic> patch(String path, {Object? body}) =>
      request('PATCH', path, body: body ?? const <String, dynamic>{});

  /// Sends a request and returns the decoded JSON. Throws [ApiException].
  /// GETs are retried once on network errors and 502/503/504. Pass
  /// `retry: true` for other calls that are safe to repeat.
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    String? idempotencyKey,
    bool? retry,
  }) async {
    final attempts = (retry ?? method == 'GET') ? 2 : 1;
    ApiException? last;
    for (var i = 0; i < attempts; i++) {
      try {
        return await _once(method, path, query, body, auth, idempotencyKey);
      } on ApiException catch (e) {
        last = e;
        final transient = e.status == 0 || e.status == 502 || e.status == 503 || e.status == 504;
        if (!transient || i == attempts - 1) rethrow;
      }
    }
    throw last ?? const ApiException(0, 'The request failed. Please try again.');
  }

  Future<dynamic> _once(
    String method,
    String path,
    Map<String, dynamic>? query,
    Object? body,
    bool auth,
    String? idempotencyKey,
  ) async {
    await loadToken();
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      if (!hasToken) {
        await _sessionExpired();
        throw const ApiException(401, 'Your session has expired. Please log in again.', 'UNAUTHORIZED');
      }
      headers['Authorization'] = 'Bearer $_token';
    }
    if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
    if (confirmDuplicateNext) {
      headers['X-Confirm-Duplicate'] = '1';
      confirmDuplicateNext = false;
    }

    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);

    final stopwatch = Stopwatch()..start();
    debugPrint('[api] -> $method $uri');
    var slowShown = false;
    final slowTimer = Timer(slowAfter, () {
      slowShown = true;
      _slowRequests++;
      if (_slowRequests == 1) {
        scaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Connecting to TrustPay. This is taking longer than usual, please wait.'),
              duration: Duration(minutes: 2),
            ),
          );
      }
    });

    http.Response res;
    try {
      final Future<http.Response> pending;
      switch (method) {
        case 'POST':
          pending = _http.post(uri, headers: headers, body: encoded);
        case 'PATCH':
          pending = _http.patch(uri, headers: headers, body: encoded);
        case 'DELETE':
          pending = _http.delete(uri, headers: headers, body: encoded);
        default:
          pending = _http.get(uri, headers: headers);
      }
      res = await pending.timeout(timeout);
    } on TimeoutException {
      debugPrint('[api] !! $method $uri timed out after ${stopwatch.elapsedMilliseconds} ms');
      throw const ApiException(0, 'The server is taking too long to answer. Please try again.', 'TIMEOUT');
    } catch (e) {
      debugPrint('[api] !! $method $uri failed after ${stopwatch.elapsedMilliseconds} ms: $e');
      throw const ApiException(
        0,
        'Cannot reach TrustPay. Check your internet connection and try again.',
        'NETWORK',
      );
    } finally {
      slowTimer.cancel();
      if (slowShown) {
        _slowRequests--;
        if (_slowRequests <= 0) {
          _slowRequests = 0;
          scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        }
      }
    }

    debugPrint('[api] <- ${res.statusCode} $method $uri (${stopwatch.elapsedMilliseconds} ms)');
    dynamic data;
    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data ?? <String, dynamic>{};
    }

    String? message;
    String? code;
    if (data is Map) {
      if (data['message'] is String) message = data['message'] as String;
      if (data['code'] != null) code = '${data['code']}';
    }
    if (res.statusCode == 401 && auth) await _sessionExpired();
    throw ApiException(res.statusCode, message ?? _defaultMessage(res.statusCode), code);
  }

  String _defaultMessage(int status) {
    switch (status) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 402:
        return 'Your balance is too low for this payment.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'We could not find that.';
      case 422:
        return 'Please check the details and try again.';
      case 423:
        return 'Your PIN was not accepted.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 502:
      case 503:
      case 504:
        return 'The server is starting up. Please try again in a moment.';
      default:
        return 'Something went wrong on our side. Please try again.';
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1) : kApiBaseUrl;
    final params = <String, String>{
      for (final e in (query ?? const <String, dynamic>{}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    final uri = Uri.parse('$base$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  /// Clears the token and sends the user to Login. Only runs once per session.
  Future<void> _sessionExpired() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    await clearToken();
    onSessionExpired?.call();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Your session expired. Please log in again.')));
  }
}

/// The app-wide client.
final ApiClient apiClient = ApiClient();
