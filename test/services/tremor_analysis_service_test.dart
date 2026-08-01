import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/tremor_analysis_service.dart';

void main() {
  const service = TremorAnalysisService();

  /// Builds a trajectory sampled at [fps] for [seconds], where the x axis is
  /// `ramp(t) + tremor(t)`. y and z are held still so the tremor lives on a
  /// single axis and the expected values stay easy to reason about.
  List<TimedLandmark> trajectory({
    required double fps,
    required double seconds,
    double rampPerSecond = 0,
    double tremorHz = 0,
    double tremorAmplitude = 0,
    double jitterMs = 0,
  }) {
    final int count = (fps * seconds).round();
    final random = math.Random(7);
    final samples = <TimedLandmark>[];

    for (int i = 0; i < count; i++) {
      final double t = i / fps;
      // Jitter models irregular frame arrival; it must not move the measured
      // frequency, which is the point of resampling before the FFT.
      final double jitter =
          jitterMs == 0 ? 0 : (random.nextDouble() - 0.5) * 2 * jitterMs;
      final double x = rampPerSecond * t +
          tremorAmplitude * math.sin(2 * math.pi * tremorHz * t);

      samples.add(TimedLandmark(
        timestampMs: (t * 1000 + jitter).round(),
        point: LandmarkPoint(x: x, y: 0, z: 0),
      ));
    }
    return samples;
  }

  group('TremorAnalysisService - separating tremor from voluntary movement -',
      () {
    test('finds a 5 Hz tremor riding on a slow ramp', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        rampPerSecond: 0.1,
        tremorHz: 5,
        tremorAmplitude: 0.01,
      ));

      expect(result.dominantFrequencyHz, isNotNull);
      expect(result.dominantFrequencyHz, closeTo(5.0, 0.5));
      expect(result.frequencyRejection, isNull);
    });

    test('does not report a pure ramp as tremor', () {
      // The same voluntary drift with no oscillation at all.
      final ramp = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        rampPerSecond: 0.1,
      ));
      final realTremor = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      // The filter leaves a little edge residue on a ramp rather than exactly
      // zero, so what matters is that it stays negligible next to real tremor
      // and below the floor where a frequency would be reported.
      expect(ramp.rms, lessThan(realTremor.rms * 0.01));
      expect(ramp.dominantFrequencyHz, isNull);
      expect(ramp.frequencyRejection, TremorFrequencyRejection.noTremorEnergy);
    });

    test('the ramp does not inflate the tremor measured alongside it', () {
      // A steep ramp carries far more positional variance than the tremor. The
      // residual metrics should barely notice it — which is exactly what
      // HandMetrics.tremorAll cannot do.
      final gentle = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        rampPerSecond: 0.05,
        tremorHz: 5,
        tremorAmplitude: 0.01,
      ));
      final steep = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        rampPerSecond: 2.0,
        tremorHz: 5,
        tremorAmplitude: 0.01,
      ));

      expect(steep.rms, closeTo(gentle.rms, gentle.rms * 0.1));
      expect(steep.dominantFrequencyHz, closeTo(5.0, 0.5));
    });

    test('vigorous voluntary movement scores far below real tremor', () {
      // 2 Hz open/close at large amplitude — a healthy person moving hard.
      final voluntary = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 2,
        tremorAmplitude: 0.15,
      ));
      // 5 Hz tremor at a fraction of that amplitude.
      final tremor = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      expect(tremor.rms, greaterThan(voluntary.rms));
    });

    test('measures amplitude in the right ballpark', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      // The 0.2s window spans one full period of 5 Hz, so the smoother removes
      // nearly all of it and the residual keeps most of the original amplitude.
      expect(result.amplitude, closeTo(0.02, 0.006));
    });
  });

  group('TremorAnalysisService - sampling rate guard -', () {
    test('refuses a frequency below 15 fps and explains why', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 12,
        seconds: 6,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      expect(result.dominantFrequencyHz, isNull);
      expect(
          result.frequencyRejection, TremorFrequencyRejection.sampleRateTooLow);
      expect(result.frequencyRejectionReason, contains('fps'));
      // The amplitude metrics survive; only the frequency is withheld.
      expect(result.rms, greaterThan(0));
    });

    test('still reports a frequency comfortably above the threshold', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      expect(result.sampleRateHz, closeTo(30, 1));
      expect(result.dominantFrequencyHz, closeTo(5.0, 0.5));
    });
  });

  group('TremorAnalysisService - irregular sampling -', () {
    test('irregular frame intervals do not move the measured frequency', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 5,
        rampPerSecond: 0.05,
        tremorHz: 5,
        tremorAmplitude: 0.02,
        jitterMs: 12,
      ));

      expect(result.dominantFrequencyHz, closeTo(5.0, 0.5));
    });

    test('orders samples that arrive out of sequence', () {
      final ordered = trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      );
      final shuffled = List<TimedLandmark>.of(ordered)
        ..shuffle(math.Random(3));

      expect(
        service.analyzeLandmark(shuffled).dominantFrequencyHz,
        closeTo(service.analyzeLandmark(ordered).dominantFrequencyHz!, 0.01),
      );
    });
  });

  group('TremorAnalysisService - consistency -', () {
    test('sustained tremor scores high', () {
      final result = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      expect(result.consistency, greaterThan(0.8));
    });

    test('a single jerk in a still hand scores lower than steady tremor', () {
      final samples = <TimedLandmark>[];
      for (int i = 0; i < 120; i++) {
        // Still, apart from a brief burst in the middle.
        final bool inBurst = i > 58 && i < 64;
        final double x = inBurst ? (i.isEven ? 0.05 : -0.05) : 0.0;
        samples.add(TimedLandmark(
          timestampMs: (i * 1000 / 30).round(),
          point: LandmarkPoint(x: x, y: 0, z: 0),
        ));
      }

      final jerk = service.analyzeLandmark(samples);
      final steady = service.analyzeLandmark(trajectory(
        fps: 30,
        seconds: 4,
        tremorHz: 5,
        tremorAmplitude: 0.02,
      ));

      expect(jerk.consistency, lessThan(steady.consistency));
    });
  });

  group('TremorAnalysisService - degenerate input -', () {
    test('returns an empty analysis for a trajectory that is too short', () {
      final result = service.analyzeLandmark(const [
        TimedLandmark(
            timestampMs: 0, point: LandmarkPoint(x: 0, y: 0, z: 0)),
        TimedLandmark(
            timestampMs: 33, point: LandmarkPoint(x: 0, y: 0, z: 0)),
      ]);

      expect(result.rms, 0);
      expect(result.dominantFrequencyHz, isNull);
      expect(result.frequencyRejection,
          TremorFrequencyRejection.insufficientSamples);
    });

    test('handles an empty trajectory without throwing', () {
      final result = service.analyzeLandmark(const []);
      expect(result.sampleCount, 0);
      expect(result.dominantFrequencyHz, isNull);
    });

    test('handles every sample sharing one timestamp', () {
      final result = service.analyzeLandmark(List.generate(
        40,
        (_) => const TimedLandmark(
            timestampMs: 1000, point: LandmarkPoint(x: 0.5, y: 0, z: 0)),
      ));

      expect(result.dominantFrequencyHz, isNull);
      expect(result.rms, 0);
    });
  });

  group('TremorAnalysisService - whole hand -', () {
    test('pools landmark spectra to find the shared frequency', () {
      // 21 landmarks all shaking at 5 Hz, each with its own offset, plus one
      // landmark that is merely drifting.
      final perLandmark = <List<TimedLandmark>>[
        for (int i = 0; i < 20; i++)
          trajectory(
            fps: 30,
            seconds: 4,
            rampPerSecond: 0.02 * i,
            tremorHz: 5,
            tremorAmplitude: 0.015,
          ),
        trajectory(fps: 30, seconds: 4, rampPerSecond: 0.3),
      ];

      final result = service.analyzeHand(perLandmark);

      expect(result.dominantFrequencyHz, closeTo(5.0, 0.5));
      expect(result.rms, greaterThan(0));
      expect(result.sampleCount, greaterThan(0));
    });

    test('returns an empty analysis when no landmark has enough data', () {
      final result = service.analyzeHand(<List<TimedLandmark>>[const [], const []]);
      expect(result.rms, 0);
      expect(result.dominantFrequencyHz, isNull);
    });
  });
}
