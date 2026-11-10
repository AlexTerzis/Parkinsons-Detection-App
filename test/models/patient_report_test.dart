import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/patient_report.dart';
import 'package:parkinsondetetion/models/test_result.dart';
import 'package:parkinsondetetion/models/test_type.dart';

PatientReport _report({String? patientName}) => PatientReport(
      id: 'r1',
      patientId: 'patient-uid-123',
      doctorId: 'doctor-uid-456',
      patientName: patientName,
      sentAt: DateTime(2026, 8, 4),
      results: <TestResult>[
        TestResult(
          id: 't1',
          patientId: 'patient-uid-123',
          type: TestType.tremor,
          performedAt: DateTime(2026, 8, 4),
          score: 0.3,
        ),
      ],
    );

void main() {
  group('PatientReport - the patient name travels with the report', () {
    // The doctor cannot read a patient's profile document — the security rules
    // give each user their own only — so the name has to be written by the
    // patient at the moment of sending. Before this, the doctor's screen listed
    // raw account ids for every patient.

    test('carries the name into Firestore', () {
      final json = _report(patientName: 'Maria Papadopoulou').toJson();

      expect(json['patientName'], 'Maria Papadopoulou');
      expect(json['patientId'], 'patient-uid-123');
    });

    test('reads the name back out', () {
      final json = _report(patientName: 'Maria Papadopoulou').toJson();
      final restored = PatientReport.fromJson(json, 'r1');

      expect(restored.patientName, 'Maria Papadopoulou');
      expect(restored.displayName, 'Maria Papadopoulou');
    });

    test('omits the field entirely when there is no name', () {
      // Rather than writing an empty string, which would then have to be
      // distinguished from a real one on the way back.
      expect(_report().toJson().containsKey('patientName'), isFalse);
    });

    group('reports written before this field existed', () {
      test('fall back to the account id', () {
        // Honest rather than blank: the lookup that would resolve these is the
        // one the rules deny, so they cannot be filled in after the fact.
        final legacy = <String, dynamic>{
          'patientId': 'patient-uid-123',
          'doctorId': 'doctor-uid-456',
          'sentAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'pending',
          'results': <dynamic>[],
          'notes': <dynamic>[],
        };

        final restored = PatientReport.fromJson(legacy, 'r0');

        expect(restored.patientName, isNull);
        expect(restored.displayName, 'patient-uid-123');
      });

      test('still parse everything else', () {
        final legacy = <String, dynamic>{
          'patientId': 'p',
          'doctorId': 'd',
          'sentAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'reviewed',
          'results': <dynamic>[],
          'notes': <dynamic>[],
        };

        final restored = PatientReport.fromJson(legacy, 'r0');

        expect(restored.status, ReportStatus.reviewed);
        expect(restored.doctorId, 'd');
      });
    });

    test('a blank name falls back rather than showing nothing', () {
      expect(_report(patientName: '   ').displayName, 'patient-uid-123');
    });
  });
}
