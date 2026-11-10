import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/ui/common/widgets/app_scaffold.dart';

/// # The bug this file exists for
///
/// `AppScaffold(scrollable: true)` wraps its body in an `IntrinsicHeight`, so
/// a body that scrolls itself — a `ListView` — is a `RenderViewport` being
/// asked for an intrinsic height, which it cannot give. The body then fails to
/// lay out *entirely* while the app bar, which is outside it, still draws. The
/// screen looks blank below the title and the console fills with
/// "RenderBox was not laid out" for every ancestor in the chain, none of which
/// names the actual mistake.
///
/// That shipped on the doctor's patient screen and read as "the doctor cannot
/// see the reports". The assertion turns it into one sentence at construction.
Widget wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('a body that scrolls itself', () {
    test('is rejected at construction rather than at layout', () {
      expect(
        () => AppScaffold(
          scrollable: true,
          body: ListView(children: const [Text('report')]),
        ),
        throwsAssertionError,
      );
    });

    test('the same goes for the other scroll views', () {
      // All three are RenderViewports, and all three fail the same way.
      expect(
        () => AppScaffold(scrollable: true, body: GridView.count(crossAxisCount: 2)),
        throwsAssertionError,
      );
      expect(
        () => AppScaffold(scrollable: true, body: CustomScrollView()),
        throwsAssertionError,
      );
    });

    testWidgets('lays out and renders once scrollable is off',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppScaffold(
            title: 'Maria K.',
            scrollable: false,
            padding: EdgeInsets.zero,
            body: SingleChildScrollView(
              child: Column(children: [Text('report body')]),
            ),
          ),
        ),
      );

      // The title alone is not the assertion: it rendered in the broken version
      // too. The body is what was missing.
      expect(find.text('Maria K.'), findsOneWidget);
      expect(find.text('report body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a real ListView body renders every child',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          AppScaffold(
            title: 'Maria K.',
            scrollable: false,
            padding: EdgeInsets.zero,
            body: ListView(
              children: const [Text('first test'), Text('second test')],
            ),
          ),
        ),
      );

      expect(find.text('first test'), findsOneWidget);
      expect(find.text('second test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('a body that does not scroll itself', () {
    testWidgets('still gets the scrolling wrapper, and can use Expanded',
        (tester) async {
      // The IntrinsicHeight pairing is there so a body can use Expanded or
      // Spacer and still scroll once scaled text outgrows the viewport. That
      // is the case the assertion must not have broken.
      await tester.pumpWidget(
        wrap(
          const AppScaffold(
            title: 'Test step',
            body: Column(
              children: [
                Text('top'),
                Spacer(),
                Text('bottom'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('top'), findsOneWidget);
      expect(find.text('bottom'), findsOneWidget);
      expect(find.byType(IntrinsicHeight), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
