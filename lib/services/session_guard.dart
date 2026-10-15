import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/app_theme.dart';
import '../utils/keys.dart';
import 'app_state.dart';
import 'settings.dart';

/// How long a signed-in account may sit untouched before the app locks.
const Duration kIdleTimeout = Duration(minutes: 2);

/// Fingerprint / face helpers (never throw).
class Biometrics {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> confirm(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Watches for touches. After [kIdleTimeout] without any (or when the app was in the background that
/// long) it opens the lock screen over whatever the customer was doing.
class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastTouch = DateTime.now();
  DateTime? _pausedAt;
  bool _locked = false;

  bool get _shouldGuard {
    final u = appState.user;
    return u != null && u.onboardingStep == 'done'; // every signed-in account, staff included
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(kIdleTimeout, _lock);
  }

  void _touch() {
    final now = DateTime.now();
    // Pointer moves fire constantly: only re-arm the timer about once a second.
    if (now.difference(_lastTouch) < const Duration(seconds: 1)) return;
    _lastTouch = now;
    if (!_locked) _restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final at = _pausedAt;
      _pausedAt = null;
      if (at != null && DateTime.now().difference(at) >= kIdleTimeout) {
        _lock();
      } else if (!_locked) {
        _restart();
      }
    }
  }

  Future<void> _lock() async {
    if (_locked || !_shouldGuard) {
      if (!_locked) _restart();
      return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    _locked = true;
    await nav.push<bool>(MaterialPageRoute(builder: (_) => const LockScreen(), fullscreenDialog: true));
    _locked = false;
    _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);
    _restart();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);
          _touch();
        },
        onPointerMove: (_) => _touch(),
        child: widget.child,
      );
}

/// Shown after the idle timeout. Unlock with fingerprint / face (if the customer turned that on in
/// Security) or sign in again with the password.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _canUseBio = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = appSettings.biometric && await Biometrics.available();
    if (!mounted) return;
    setState(() => _canUseBio = ok);
    if (ok) _unlock();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final ok = await Biometrics.confirm('Unlock TrustPay');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _message = 'Could not verify you. Try again or use your password.';
      });
    }
  }

  Future<void> _password() async {
    setState(() => _busy = true);
    await appState.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: TpColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: TpColors.primary),
                const SizedBox(height: 18),
                const Text('Session locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  _canUseBio
                      ? 'You were away for a while. Unlock with your fingerprint or face to continue.'
                      : 'You were away for a while, so we signed you out to keep your money safe. Log in again to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4, color: TpColors.muted),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: TpColors.danger)),
                ],
                const SizedBox(height: 28),
                if (_canUseBio) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy && !_canUseBio ? null : _password,
                    child: Text(_canUseBio ? 'Use password instead' : 'Log in again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
