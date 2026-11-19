import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/voice_api_service.dart';

void main() {
  group('VoicePrediction -', () {
    test('accepts a versioned usable research score', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'model_version': 'praat16_subject_grouped_v2',
        'result_status': 'ok',
        'validated_for_clinical_use': true,
        'screening_score': .42,
        'decision_threshold': .7,
        'input_quality': <String, dynamic>{'warnings': <String>[]},
      });

      expect(prediction.isUsable, isTrue);
      expect(prediction.screeningScore, .42);
      expect(prediction.decisionThreshold, .7);
    });

    test('keeps an abstained response scoreless', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'model_version': 'praat16_subject_grouped_v2',
        'result_status': 'outside_reference_range',
        'validated_for_clinical_use': false,
        'screening_score': null,
        'experimental_model_score': .997,
        'decision_threshold': .7,
        'input_quality': <String, dynamic>{
          'warnings': <String>[
            'recording_does_not_match_training_distribution',
          ],
        },
      });

      expect(prediction.isUsable, isFalse);
      expect(prediction.screeningScore, isNull);
      expect(prediction.warnings, isNotEmpty);
    });

    test('rejects a score from a model marked as unvalidated', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'model_version': 'praat16_subject_grouped_v2',
        'validated_for_clinical_use': false,
        'result_status': 'ok',
        'screening_score': .997,
        'decision_threshold': .7,
        'input_quality': <String, dynamic>{'warnings': <String>[]},
      });

      expect(prediction.status, 'research_model_not_validated');
      expect(prediction.isUsable, isFalse);
      expect(prediction.screeningScore, isNull);
    });

    test('builds a descriptive acoustic result without a health score', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'model_version': 'praat16_subject_grouped_v2',
        'validated_for_clinical_use': false,
        'result_status': 'research_model_not_validated',
        'screening_score': null,
        'experimental_model_score': .997,
        'decision_threshold': .7,
        'features': <String, dynamic>{
          'MDVP:Fo(Hz)': 150,
          'MDVP:Jitter(%)': .006,
          'MDVP:Shimmer': .03,
          'HNR': 22,
        },
        'input_quality': <String, dynamic>{
          'warnings': <String>['model_not_validated_for_phone_recordings'],
          'duration_seconds': 5,
          'voiced_fraction': .95,
          'clipped_fraction': 0,
          'z_scores': <String, dynamic>{
            'MDVP:Jitter(%)': 0,
            'MDVP:Shimmer': 0,
            'HNR': 0,
          },
        },
      });

      expect(prediction.isUsable, isFalse);
      expect(prediction.screeningScore, isNull);
      expect(prediction.acousticAnalysis, isNotNull);
      expect(prediction.experimentalModelScore, .997);
      expect(prediction.acousticAnalysis!.overallScore, closeTo(.575, .001));
      expect(prediction.acousticAnalysis!.jitterPercent, closeTo(.6, .001));
      expect(prediction.acousticAnalysis!.shimmerPercent, closeTo(3, .001));
    });

    test('does not score an acoustically unusable capture', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'model_version': 'praat16_subject_grouped_v2',
        'validated_for_clinical_use': false,
        'result_status': 'capture_quality_failed',
        'screening_score': null,
        'features': <String, dynamic>{
          'MDVP:Fo(Hz)': 150,
          'MDVP:Jitter(%)': .006,
          'MDVP:Shimmer': .03,
          'HNR': 22,
        },
        'input_quality': <String, dynamic>{
          'warnings': <String>['insufficient_sustained_voice'],
          'duration_seconds': 5,
          'voiced_fraction': .2,
          'clipped_fraction': 0,
          'z_scores': <String, dynamic>{
            'MDVP:Jitter(%)': 0,
            'MDVP:Shimmer': 0,
            'HNR': 0,
          },
        },
      });

      expect(prediction.acousticAnalysis, isNull);
    });

    test('rejects the old unversioned 99 percent response', () {
      final prediction = VoicePrediction.fromJson(<String, dynamic>{
        'probability_PD': .99,
        'predicted_class': 1,
      });

      expect(prediction.status, 'legacy_model');
      expect(prediction.isUsable, isFalse);
      expect(prediction.screeningScore, isNull);
    });
  });
}
