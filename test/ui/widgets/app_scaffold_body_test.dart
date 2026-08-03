import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/ui/common/widgets/widgets.dart';

/// Regression tests for AppScaffold actually rendering its body.
///
/// The scrollable wrapper once passed `IntrinsicHeight` a reassigned local
/// captured by the LayoutBuilder's closure, so at layout time the scaffold
/// became its own descendant. IntrinsicHeight then asked LayoutBuilder for an
/// intrinsic height it cannot supply, and every scrollable body failed to lay
/// out — while the bottom action bar, which lives outside the body, kept
/// rendering. On screen that looked like a working button on an empty page,
/// which is why it read as "the button does nothing" rather than as a crash.
///
/// These assert the body is on screen, not merely that the frame builds.
void main() {
  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  group('AppScaffold body -', () {
    testWidgets('renders a plain body alongside a bottom action',
        (tester) async {
      await tester.pumpWidget(host(
        AppScaffold(
          title: 'Voice',
          bottomAction: PrimaryAction(label: 'Start', onPressed: () {}),
          body: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('BODY-TEXT')],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('BODY-TEXT'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('renders a body that uses Expanded', (tester) async {
      // Expanded is why the IntrinsicHeight is there at all, so it is the case
      // most worth pinning.
      await tester.pumpWidget(host(
        const AppScaffold(
          body: Column(
            children: [
              Text('HEADER'),
              Expanded(child: Text('EXPANDED-BODY')),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('EXPANDED-BODY'), findsOneWidget);
    });

    testWidgets('renders a non-scrollable body', (tester) async {
      await tester.pumpWidget(host(
        const AppScaffold(
          scrollable: false,
          body: Center(child: Text('STATIC-BODY')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('STATIC-BODY'), findsOneWidget);
    });

    testWidgets('still renders the body at the largest text scale',
        (tester) async {
      // The scrollable wrapper exists for scaled text; check it survives it.
      await tester.pumpWidget(host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: AppScaffold(
            bottomAction: PrimaryAction(label: 'Next', onPressed: () {}),
            body: const Column(
              children: [
                Text('HEADER'),
                Expanded(child: Text('SCALED-BODY')),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SCALED-BODY'), findsOneWidget);
    });
  });

  group('TestStepScaffold body -', () {
    testWidgets('renders its child, instruction and Next button',
        (tester) async {
      await tester.pumpWidget(host(
        TestStepScaffold(
          title: 'Digits',
          instruction: 'Remember these numbers',
          onNext: () {},
          child: const Center(child: Text('STEP-CHILD')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('STEP-CHILD'), findsOneWidget);
      expect(find.text('Remember these numbers'), findsOneWidget);
    });

    testWidgets('the Next button reaches its callback', (tester) async {
      // The visible symptom was a button that did nothing, so tapping it is
      // part of the regression, not just finding it.
      var tapped = false;
      await tester.pumpWidget(host(
        TestStepScaffold(
          title: 'Digits',
          onNext: () => tapped = true,
          child: const Center(child: Text('STEP-CHILD')),
        ),
      ));
      await tester.pumpAndSettle();

      // Tapped via PrimaryAction rather than FilledButton: the icon variant
      // builds a private FilledButton subclass, which byType does not match.
      await tester.tap(find.byType(PrimaryAction));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
