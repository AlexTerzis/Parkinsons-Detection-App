import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's app-wide text-size preference and persists it.
///
/// Mirrors [LocalizationService]: a [ChangeNotifier] resolved from the
/// locator, initialised from `main()` before `runApp`, and driving a
/// root-level rebuild.
class TextScaleService extends ChangeNotifier {
  static const _textScaleKey = 'textScale';

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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_textScaleKey);
    if (saved != null) {
      _scale = saved.clamp(minScale, maxScale);
      return;
    }

    // First run only: adopt whatever font size the OS is already set to, so
    // someone who has asked their device for larger type does not get it
    // taken away. The MediaQuery override replaces the platform scaler rather
    // than composing with it, so without this the app would start smaller
    // than the rest of their phone.
    _scale = WidgetsBinding.instance.platformDispatcher.textScaleFactor
        .clamp(minScale, maxScale);
  }

  Future<void> setScale(double scale) async {
    final next = scale.clamp(minScale, maxScale);
    if (next == _scale) return;

    _scale = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, next);
    notifyListeners();
  }

  Future<void> setStepIndex(int index) =>
      setScale(steps[index.clamp(0, steps.length - 1)]);

  Future<void> reset() => setScale(defaultScale);
}
