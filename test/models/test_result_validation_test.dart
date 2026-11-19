import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_type.dart';

void main() {
  _typeRoundTrip();

  TestResult result(TestType type, Map<String, dynamic> data) => TestResult(
        id: 'result',
        patientId: 'patient',
        type: type,
        performedAt: DateTime(2026),
        score: .997,
        data: data,
      );

  test('an old unvalidated voice score is excluded from patient use', () {
    expect(result(TestType.voice, const {}).isValidatedForPatientUse, isFalse);
  });

  test('a future independently validated voice result is eligible', () {
    expect(
      result(TestType.voice, const <String, dynamic>{
        'validatedForClinicalUse': true,
      }).isValidatedForPatientUse,
      isTrue,
    );
  });

  test('an explicitly approved prototype is visible but not clinical', () {
    final prototype = result(TestType.voice, const <String, dynamic>{
      'displayAsExperimentalPrototype': true,
      'validatedForClinicalUse': false,
    });

    expect(prototype.isValidatedForPatientUse, isTrue);
    expect(prototype.isExperimentalVoicePrototype, isTrue);
    expect(prototype.isEligibleForClinicalSummary, isFalse);
  });

  test('the voice-specific rule does not hide other test types', () {
    expect(result(TestType.tremor, const {}).isValidatedForPatientUse, isTrue);
  });
}

/// Every `TestType` must survive a write and read back as itself.
///
/// `_typeFromString` falls back to `cameraDetection` for anything it does not
/// recognise, so a type missing from its switch does not fail — it comes back
/// as the wrong test entirely. That is how posture results came to be labelled
/// as camera ones on both the patient's list and the doctor's report, with
/// nothing anywhere to say so.
void _typeRoundTrip() {
  group('test type round-trip', () {
    for (final type in TestType.values) {
      test('${type.name} reads back as itself', () {
        final written = TestResult(
          id: 'x',
          patientId: 'p',
          type: type,
          performedAt: DateTime(2026, 8, 4),
          score: 0.3,
        ).toJson();

        expect(
          TestResult.fromJson(written, 'x').type,
          type,
          reason: 'add a case for "${type.name}" to _typeFromString',
        );
      });
    }
  });
}
