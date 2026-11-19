import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's app-wide text-size preference and persists it.
///
/// Mirrors [LocalizationService]: a [ChangeNotifier] resolved from the
/// locator, initialised from `main()` before `runApp`, and driving a
/// root-level rebuild.
class TextScaleService extends ChangeNotifier {
  /// The size this device starts at, used by anyone with no size of their own.
  ///
  /// Set from the sign-in screen, where there is no account to attach it to. A
  /// tablet stood in a waiting room can be left on a comfortable size once and
  /// have every patient inherit it.
  static const _deviceKey = 'textScale';

  /// One account's chosen size.
  ///
  /// Scoped per uid because the app runs on shared tablets: with a single
  /// device-wide key, a doctor who set the largest size handed that size to
  /// whoever signed in next, and nothing in the UI explained why.
  static String _userKey(String uid) => 'textScale_$uid';

  /// The sizes offered in the UI.
  ///
  /// Discrete presets rather than a continuous range: a slider needs a
  /// sustained, precise drag, which is the worst possible control for someone
  /// with hand tremor. Four fixed options are one tap each, and a mis-tap
  /// lands on a neighbouring size rather than somewhere wild.
  static const List<double> steps = <double>[1.0, 1.15, 1.3, 1.5];

  static const double defaultScale = 1.0;

  /// Never below 1.0: this audience should not be able to shrink text.
  static const double minScale = 1.0;

  /// Above ~1.5 the app's remaining fixed-height constructs (charts, some
  /// test steps) break rather than merely reflow.
  static const double maxScale = 1.5;

  /// Ceiling for tab labels specifically.
  ///
  /// Flutter sizes a tab bar with both icon and text from a compile-time
  /// constant that does not grow with the text scaler, and both tab bars in
  /// this app run with `toolbarHeight: 0` — the tab bar *is* the app bar — so
  /// an overflow there is impossible to miss.
  static const double maxTabScale = 1.15;

  double _scale = defaultScale;
  double get scale => _scale;

  TextScaler get textScaler => TextScaler.linear(_scale);

  TextScaler get tabBarTextScaler =>
      TextScaler.linear(_scale.clamp(minScale, maxTabScale));

  /// Index of the current scale within [steps], or 0 if it matches none.
  int get stepIndex {
    final index = steps.indexWhere((s) => (s - _scale).abs() < 0.001);
    return index == -1 ? 0 : index;
  }

  /// Whose size is currently loaded, or null while signed out.
  String? _uid;

  /// Loads the size for [uid] before the first frame.
  ///
  /// Takes the uid rather than reading it from the auth service so `main()`
  /// can resolve it once and hand it over, keeping this a plain preference
  /// store with no dependency on how sign-in works.
  Future<void> init({String? uid}) async {
    _uid = uid;
    await _load();
  }

  /// Switches to [uid]'s size, or back to the device size when signed out.
  ///
  /// Driven by the auth state stream, so it covers signing out, signing in and
  /// switching accounts without each of those call sites having to remember.
  /// Upgrading a guest to a real account keeps the same uid, so that case is a
  /// no-op and the size they picked as a guest survives.
  Future<void> loadForUser(String? uid) async {
    if (uid == _uid) return;

    _uid = uid;
    final previous = _scale;
    await _load();
    if (_scale != previous) notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;

    // Their own size, else this device's, else the size the OS is already set
    // to: someone who has asked their phone for larger type should not have it
    // taken away here. The MediaQuery override replaces the platform scaler
    // rather than composing with it, so without that last fallback the app
    // would start smaller than the rest of their phone.
    final resolved = (uid == null ? null : prefs.getDouble(_userKey(uid))) ??
        prefs.getDouble(_deviceKey) ??
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;

    _scale = resolved.clamp(minScale, maxScale);
  }

  Future<void> setScale(double scale) async {
    final next = scale.clamp(minScale, maxScale);
    if (next == _scale) return;

    _scale = next;
    final uid = _uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(uid == null ? _deviceKey : _userKey(uid), next);
    notifyListeners();
  }

  Future<void> setStepIndex(int index) =>
      setScale(steps[index.clamp(0, steps.length - 1)]);

  Future<void> reset() => setScale(defaultScale);
}
