import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_theme.dart';

/// Loads data from the server and shows a spinner, an error with "Try again", or [builder].
/// While reloading, the old data stays visible. [reload] is passed to [builder] for pull-to-refresh
/// and buttons. Change [reloadKey] (for example `appState.txnVersion`) to reload from outside.
class ApiBuilder<T> extends StatefulWidget {
  const ApiBuilder({super.key, required this.load, required this.builder, this.reloadKey, this.loading});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final Object? reloadKey;

  /// Shown instead of the default spinner on first load.
  final Widget? loading;

  @override
  State<ApiBuilder<T>> createState() => _ApiBuilderState<T>();
}

class _ApiBuilderState<T> extends State<ApiBuilder<T>> {
  T? _data;
  bool _has = false;
  Object? _error;
  bool _busy = true;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(covariant ApiBuilder<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) _run();
  }

  Future<void> _run() async {
    final round = ++_round;
    if (mounted) setState(() => _busy = true);
    try {
      final data = await widget.load();
      if (!mounted || round != _round) return;
      setState(() {
        _data = data;
        _has = true;
        _error = null;
        _busy = false;
      });
    } catch (e) {
      if (!mounted || round != _round) return;
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_has) return widget.builder(context, _data as T, _run);
    if (_busy) {
      return widget.loading ?? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    return ErrorRetry(message: errorMessage(_error ?? ''), onRetry: _run);
  }
}

/// Friendly error with a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: TpColors.muted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4, color: TpColors.muted)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
