import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/keys.dart';
import 'app_state.dart';
import 'trustpay_api.dart';

/// Keeps the unread count for the bell and pops a small alert when something new arrives while the app
/// is open. (Phone push when the app is closed needs Firebase; see the backend notes.)
class NotificationService extends ChangeNotifier {
  Timer? _timer;
  int _unread = 0;
  String? _lastSeenId;
  bool _first = true;

  int get unread => _unread;

  void start() {
    _timer?.cancel();
    _first = true;
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _unread = 0;
    _lastSeenId = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!appState.signedIn) return;
    try {
      final r = await api.notificationsUnread();
      final latest = r['latest'] is Map ? asMap(r['latest']) : null;
      final count = asInt(r['unread']);
      final id = latest == null ? null : asStr(latest['id']);
      if (!_first && latest != null && id != _lastSeenId) {
        scaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${asStr(latest['title'])}${asStr(latest['body']).isEmpty ? '' : '\n${asStr(latest['body'])}'}', maxLines: 3, overflow: TextOverflow.ellipsis),
            duration: const Duration(seconds: 5),
          ));
        // A new alert usually means money moved: refresh the balance.
        appState.refreshUser();
      }
      _lastSeenId = id;
      _first = false;
      if (count != _unread) {
        _unread = count;
        notifyListeners();
      }
    } catch (_) {
      // Quiet: the next tick tries again.
    }
  }

  void markedRead() {
    _unread = 0;
    notifyListeners();
  }
}

final NotificationService appNotifications = NotificationService();
