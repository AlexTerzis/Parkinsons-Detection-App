import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/ui/common/widgets/widgets.dart';

import 'widget_test_harness.dart';

void main() {
  group('AppGap', () {
    testWidgets('sizes itself on the spacing scale', (tester) async {
      await pumpComponent(
        tester,
        const Column(children: [AppGap.md()]),
      );

      final size = tester.getSize(find.byType(AppGap));
      expect(size.height, AppSpacing.md);
    });

    testWidgets('the wide variant takes width instead of height',
        (tester) async {
      await pumpComponent(
        tester,
        const Row(children: [AppGap.wide(AppSpacing.lg)]),
      );

      final size = tester.getSize(find.byType(AppGap));
      expect(size.width, AppSpacing.lg);
    });
  });

  group('AppCard', () {
    testWidgets('renders its child', (tester) async {
      await pumpComponent(
        tester,
        const AppCard(child: Text('contents')),
      );

      expect(find.text('contents'), findsOneWidget);
    });

    testWidgets('is not tappable without onTap', (tester) async {
      await pumpComponent(
        tester,
        const AppCard(child: Text('contents')),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('reports taps when given onTap', (tester) async {
      var taps = 0;
      await pumpComponent(
        tester,
        AppCard(onTap: () => taps++, child: const Text('contents')),
      );

      await tester.tap(find.text('contents'));
      expect(taps, 1);
    });
  });

  group('AppTileCard', () {
    testWidgets('shows title, subtitle and a chevron when tappable',
        (tester) async {
      await pumpComponent(
        tester,
        AppTileCard(
          icon: Icons.science,
          title: 'Tremor test',
          subtitle: 'Not yet taken',
          onTap: () {},
        ),
      );

      expect(find.text('Tremor test'), findsOneWidget);
      expect(find.text('Not yet taken'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('meets the enlarged minimum tap target', (tester) async {
      await pumpComponent(
        tester,
        AppTileCard(title: 'Tremor test', onTap: () {}),
      );

      // The audience has hand tremor, so rows are deliberately taller than the
      // Material default of 48.
      final height = tester.getSize(find.byType(ListTile)).height;
      expect(height, greaterThanOrEqualTo(AppSize.minTap));
    });

    testWidgets('omits the chevron when there is nothing to open',
        (tester) async {
      await pumpComponent(tester, const AppTileCard(title: 'Read only'));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('state views', () {
    testWidgets('AppLoading shows a spinner and its caption', (tester) async {
      await pumpComponent(tester, const AppLoading(message: 'Saving'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving'), findsOneWidget);
    });

    testWidgets('AppEmptyState renders its call to action', (tester) async {
      var pressed = false;
      await pumpComponent(
        tester,
        AppEmptyState(
          icon: Icons.inbox,
          title: 'Nothing here',
          message: 'Take a test to see results',
          action: FilledButton(
            onPressed: () => pressed = true,
            child: const Text('Start'),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Take a test to see results'), findsOneWidget);

      await tester.tap(find.text('Start'));
      expect(pressed, isTrue);
    });

    testWidgets('AppErrorState retries', (tester) async {
      var retries = 0;
      await pumpComponent(
        tester,
        AppErrorState(
          message: 'Camera unavailable',
          onRetry: () => retries++,
          retryLabel: 'Try again',
        ),
      );

      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });
  });

  group('PrimaryAction', () {
    testWidgets('fires when enabled', (tester) async {
      var pressed = false;
      await pumpComponent(
        tester,
        PrimaryAction(label: 'Next', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Next'));
      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpComponent(
        tester,
        const PrimaryAction(label: 'Next', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('blocks input and shows a spinner while busy', (tester) async {
      var pressed = false;
      await pumpComponent(
        tester,
        PrimaryAction(
          label: 'Sign in',
          busy: true,
          onPressed: () => pressed = true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      expect(pressed, isFalse);
    });
  });

  group('ScoreBar', () {
    testWidgets('renders the value as text, not just as bar length',
        (tester) async {
      await pumpComponent(
        tester,
        const ScoreBar(label: 'Tremor', value: 0.42),
      );

      expect(find.text('Tremor'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('clamps out-of-range model output instead of throwing',
        (tester) async {
      await pumpComponent(
        tester,
        const ScoreBar(label: 'Tremor', value: 1.0000001),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SpeechTextField', () {
    testWidgets('disables the mic while it is already listening',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpComponent(
        tester,
        SpeechTextField(
          controller: controller,
          listening: true,
          onListen: () {},
          label: 'Answer',
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('starts dictation when idle', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var listened = false;

      await pumpComponent(
        tester,
        SpeechTextField(
          controller: controller,
          listening: false,
          onListen: () => listened = true,
          label: 'Answer',
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(listened, isTrue);
    });

    testWidgets('marks correctness with an icon, never colour alone',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpComponent(
        tester,
        SpeechTextField(
          controller: controller,
          listening: false,
          onListen: () {},
          correct: true,
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows its title, subtitle and action', (tester) async {
      await pumpComponent(
        tester,
        SectionHeader(
          'Results',
          subtitle: 'Last 30 days',
          action: TextButton(onPressed: () {}, child: const Text('Export')),
        ),
      );

      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });
  });

  group('HintPanel', () {
    testWidgets('bullets every line it is given', (tester) async {
      await pumpComponent(
        tester,
        const HintPanel(lines: ['A kind of fruit', 'Something you eat']),
      );

      expect(find.text('• A kind of fruit'), findsOneWidget);
      expect(find.text('• Something you eat'), findsOneWidget);
    });
  });
}
