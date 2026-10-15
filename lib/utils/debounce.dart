import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs the latest call after the user stops typing for [delay].
class Debouncer {
  Debouncer([this.delay = const Duration(milliseconds: 450)]);

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
