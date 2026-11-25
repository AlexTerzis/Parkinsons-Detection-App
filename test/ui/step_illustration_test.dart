import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/camera_task_protocol.dart';
import 'package:parkinsondetetion/ui/views/camera_test/step_illustration.dart';

void main() {
  group('StepIllustration', () {
    for (final type in CameraTaskType.values) {
      for (final hand in <String?>[null, 'Right', 'Left']) {
        testWidgets('draws ${type.name} for ${hand ?? 'both hands'}',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Center(child: StepIllustration(type: type, hand: hand)),
          ));
          // Run part of the animation loop; any painting error throws here.
          for (int i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 120));
          }
          expect(find.byType(StepIllustration), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('stays still when the system asks for reduced motion',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StepIllustration(
              type: CameraTaskType.fingerTap, hand: 'Right'),
        ),
      ));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
