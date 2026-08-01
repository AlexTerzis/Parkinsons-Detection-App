import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/ui/common/widgets/widgets.dart';

import 'widget_test_harness.dart';

/// The app ships a user-facing text-size setting, so every shared component has
/// to survive a large scaler without overflowing. These tests pump each one at
/// 2x on a phone-sized surface and assert nothing was clipped.
///
/// `takeException` is the check that matters: a RenderFlex overflow surfaces as
/// a thrown FlutterError during layout, which is exactly the failure a reviewer
/// would otherwise only catch by eye on a device.
void main() {
  const phone = Size(360, 690);

  Future<void> pumpAtScale(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpComponent(tester, child, textScale: 2.0);
  }

  testWidgets('AppTileCard does not overflow at 2x text', (tester) async {
    await pumpAtScale(
      tester,
      AppTileCard(
        icon: Icons.psychology,
        title: 'Neuropsychological assessment',
        subtitle: 'Fifteen steps, about twenty minutes',
        onTap: () {},
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('MetricRow wraps a long value instead of overflowing',
      (tester) async {
    await pumpAtScale(
      tester,
      const MetricRow(
        label: 'Most recent assessment',
        value: '12 September 2026, 14:35',
        icon: Icons.event,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ScoreBar keeps its percentage readable at 2x', (tester) async {
    await pumpAtScale(
      tester,
      const ScoreBar(label: 'Visuoconstructional skills', value: 0.67),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('AppEmptyState survives a long message at 2x', (tester) async {
    await pumpAtScale(
      tester,
      const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No results yet',
        message: 'Complete at least one test to see your results here.',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('SectionHeader keeps its action beside a long title',
      (tester) async {
    await pumpAtScale(
      tester,
      SectionHeader(
        'Second opinions from other doctors',
        action: TextButton(onPressed: () {}, child: const Text('See all')),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('PrimaryAction grows with the text rather than clipping it',
      (tester) async {
    await pumpAtScale(
      tester,
      const PrimaryAction(
        label: 'Send my results to my doctor',
        icon: Icons.send,
        onPressed: null,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('HintPanel wraps long hint lines', (tester) async {
    await pumpAtScale(
      tester,
      const HintPanel(
        lines: [
          'They are both means of transport that move people around',
          'They both measure something',
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
