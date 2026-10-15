import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device preferences: dark mode and "unlock with fingerprint / face after a timeout".
class AppSettings extends ChangeNotifier {
  static const _darkKey = 'tp_dark';
  static const _bioKey = 'tp_biometric';

  bool _dark = false;
  bool _biometric = false;

  bool get dark => _dark;

  /// When true, the idle lock screen can be opened with fingerprint / face instead of a password.
  bool get biometric => _biometric;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _dark = p.getBool(_darkKey) ?? false;
      _biometric = p.getBool(_bioKey) ?? false;
    } catch (_) {
      // Defaults are fine when storage is not available.
    }
  }

  Future<void> setDark(bool v) async {
    _dark = v;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setBool(_darkKey, v);
    } catch (_) {}
  }

  Future<void> setBiometric(bool v) async {
    _biometric = v;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setBool(_bioKey, v);
    } catch (_) {}
  }
}

final AppSettings appSettings = AppSettings();

/// Dark mode is applied to the whole app as a colour filter (invert + hue rotate 180°), which keeps
/// brand blues blue. Pictures that must stay true (QR codes, camera preview) are wrapped in [DarkSafe].
const ColorFilter kDarkFilter = ColorFilter.matrix(<double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

const ColorFilter kNormalFilter = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Shows [child] with its real colours even when dark mode is on.
class DarkSafe extends StatelessWidget {
  const DarkSafe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => appSettings.dark ? ColorFiltered(colorFilter: kDarkFilter, child: child) : child,
      );
}
