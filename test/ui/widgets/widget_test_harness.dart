import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/ui/common/app_theme.dart';

/// Wraps a widget in the app's real theme and localizations.
///
/// Components are tested against `AppTheme.light()` rather than a bare
/// `MaterialApp`, because the theme is where most of their behaviour lives —
/// the tap-target floor, the card border, the input decoration. A test against
/// the default theme would pass while the shipped widget looked wrong.
Widget wrapForTest(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: child),
    ),
  );
}

/// Pumps [child] inside [wrapForTest].
///
/// Pumps a single frame rather than calling `pumpAndSettle`. Several of these
/// components legitimately animate forever — an indeterminate
/// [CircularProgressIndicator] never comes to rest — and `pumpAndSettle` would
/// time out rather than report anything useful about the widget.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    wrapForTest(child, locale: locale, textScale: textScale),
  );
  await tester.pump();
}
