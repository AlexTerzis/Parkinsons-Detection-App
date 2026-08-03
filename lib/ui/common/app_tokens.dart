import 'package:flutter/material.dart';

/// Raw design tokens.
///
/// Deliberately free of [ThemeData] and [BuildContext] so it can be imported
/// anywhere, including painters and services. Prefer resolving colours through
/// `Theme.of(context).colorScheme` in widgets; reach for these constants only
/// for the fixed-contract colours documented below, or when building a
/// [ThemeData].
abstract final class AppTokens {
  // --- Brand (Calm Teal) -----------------------------------------------
  static const Color primary = Color(0xFF146B63);
  static const Color primaryDark = Color(0xFF0A3D38);
  static const Color secondary = Color(0xFF4E9A93);

  /// Reserved for genuine accents. Used sparingly by design; reaching for this
  /// instead of [primary] should be a deliberate choice.
  static const Color accent = Color(0xFF1B5FA8);

  // --- Neutrals ----------------------------------------------------------
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F6F5);
  static const Color pageBackground = Color(0xFFF7FAF9);
  static const Color onSurface = Color(0xFF12211F);
  static const Color onSurfaceMuted = Color(0xFF40514E);

  /// Borders for interactive elements (text fields, focus rings). 5.2:1 on
  /// white, which clears the 3:1 WCAG 1.4.11 floor for non-text contrast.
  static const Color outline = Color(0xFF5E706D);

  /// Decorative hairlines and dividers only. At 1.6:1 on white this is far
  /// below the contrast floor, so it must never carry an interactive border.
  static const Color outlineVariant = Color(0xFFBFD0CD);

  // --- Semantic ----------------------------------------------------------
  static const Color success = Color(0xFF2E7D5B);

  /// 3.7:1 on white: safe as a fill, icon or border, but never as body text.
  /// Use `AppSemanticColors.warningContainer` behind text instead.
  static const Color warning = Color(0xFFB5791F);
  static const Color error = Color(0xFFB3261E);

  // --- Fixed, non-themeable colours --------------------------------------
  // These answer to something other than the eye. Do not swap them for
  // ColorScheme roles, however tempting it looks during a theme sweep.

  /// Drawing-test canvas and pen. `assets/models/drawing_binary_classifier2.tflite`
  /// is trained on black ink on white paper, so these are model inputs, not
  /// styling. Changing them degrades classification accuracy while the UI
  /// still looks perfectly correct.
  static const Color canvasPaper = Color(0xFFFFFFFF);
  static const Color canvasInk = Color(0xFF000000);

  /// Scrim and foreground for content layered over a live camera preview.
  /// Theme-derived foregrounds risk dark-on-dark here.
  static const Color overlayScrim = Color(0x8A000000);
  static const Color onOverlay = Color(0xFFFFFFFF);

  /// Splash background. Coupled to `flutter_native_splash.color` and
  /// `android_12.icon_background_color` in pubspec.yaml — changing this
  /// without re-running `dart run flutter_native_splash:create` produces a
  /// colour flash on cold start.
  static const Color splashBackground = Color(0xFF071833);
}

/// 4-point spacing scale. The app already clustered on these values; the scale
/// exists so new code has a vocabulary and the stragglers have somewhere to go.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii, collapsed from the fourteen distinct values the app had grown.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

abstract final class AppOpacity {
  static const double subtle = 0.08;
  static const double muted = 0.24;
  static const double strong = 0.60;
}

abstract final class AppSize {
  /// Minimum edge length for interactive elements. The audience for this app
  /// frequently has hand tremor, so targets are deliberately larger than the
  /// Material default of 48.
  ///
  /// Note this is unreachable for [Checkbox], [Radio] and [Switch]: the
  /// framework caps their tap target at 48. Wrap those in a list tile instead.
  static const double minTap = 50;

  static const double iconMd = 26;
}
