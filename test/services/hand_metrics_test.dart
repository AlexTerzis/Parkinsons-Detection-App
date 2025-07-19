import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/hand_metrics.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';

void main() {
  final metrics = HandMetrics();
  group('HandMetrics', () {
    test('speed variance near zero for stationary trajectory', () {
      final frames = [
        [
          const LandmarkPoint(x: 0, y: 0, z: 0),
          const LandmarkPoint(x: 0, y: 0, z: 0),
          const LandmarkPoint(x: 0, y: 0, z: 0),
        ]
      ];
      final result = metrics.speedVarianceAll(frames);
      expect(result, closeTo(0, 1e-6));
    });

    test('tremor detects oscillation', () {
      final points = List<LandmarkPoint>.generate(20, (i) {
        final x = (i % 2 == 0) ? 0.0 : 1.0;
        return LandmarkPoint(x: x, y: 0, z: 0);
      });
      final tremor = metrics.tremorAll([points]);
      expect(tremor, greaterThan(0.2));
    });
  });
}
