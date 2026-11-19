import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/appointment.dart';

Appointment _appointment({
  String? patientName,
  String? doctorName,
  AppointmentStatus status = AppointmentStatus.requested,
  DateTime? proposedFor,
}) =>
    Appointment(
      id: 'a1',
      patientId: 'patient-uid-123',
      doctorId: 'doctor-uid-456',
      patientName: patientName,
      doctorName: doctorName,
      requestedFor: DateTime(2026, 8, 12, 10),
      requestedAt: DateTime(2026, 8, 4, 9),
      status: status,
      patientNote: 'Tremor has been worse this week.',
      proposedFor: proposedFor,
    );

void main() {
  group('Appointment', () {
    group('names travel on the document', () {
      test('the patient name is written, as it is on a report', () {
        // The doctor cannot read a patient's profile — the rules give each user
        // their own only — so the name has to come with the appointment.
        final json = _appointment(patientName: 'Maria P').toJson();

        expect(json['patientName'], 'Maria P');
      });

      test('both names survive a round trip', () {
        final json =
            _appointment(patientName: 'Maria P', doctorName: 'Dr Ionescu')
                .toJson();
        final restored = Appointment.fromJson(json, 'a1');

        expect(restored.patientDisplayName, 'Maria P');
        expect(restored.doctorDisplayName, 'Dr Ionescu');
      });

      test('fall back to the account id when absent', () {
        final restored =
            Appointment.fromJson(_appointment().toJson(), 'a1');

        expect(restored.patientDisplayName, 'patient-uid-123');
        expect(restored.doctorDisplayName, 'doctor-uid-456');
      });

      test('a blank name falls back rather than showing nothing', () {
        expect(_appointment(patientName: '  ').patientDisplayName,
            'patient-uid-123');
      });
    });

    group('serialization', () {
      test('carries the times and the status', () {
        final json = _appointment().toJson();

        expect(json['status'], 'requested');
        expect((json['requestedFor'] as Timestamp).toDate(),
            DateTime(2026, 8, 12, 10));
        expect(json['patientNote'], isNotNull);
      });

      test('omits absent optional fields rather than writing nulls', () {
        final json = _appointment().toJson();

        expect(json.containsKey('patientName'), isFalse);
        expect(json.containsKey('doctorMessage'), isFalse);
        expect(json.containsKey('proposedFor'), isFalse);
      });

      test('an unknown status reads as requested rather than throwing', () {
        // Forward compatibility: a status added by a later version must not
        // crash an older client reading the document.
        final restored = Appointment.fromJson(<String, dynamic>{
          'patientId': 'p',
          'doctorId': 'd',
          'status': 'rescheduled_twice',
          'requestedFor': Timestamp.fromDate(DateTime(2026)),
          'requestedAt': Timestamp.fromDate(DateTime(2026)),
        }, 'a1');

        expect(restored.status, AppointmentStatus.requested);
      });

      test('a document missing its times still parses', () {
        final restored = Appointment.fromJson(
          <String, dynamic>{'patientId': 'p', 'doctorId': 'd'},
          'a1',
        );

        expect(restored.requestedFor, isNotNull);
        expect(restored.status, AppointmentStatus.requested);
      });
    });

    group('which time an appointment is actually for', () {
      test('is the requested one until the doctor proposes another', () {
        expect(_appointment().effectiveTime, DateTime(2026, 8, 12, 10));
      });

      test('becomes the doctor\'s counter-offer once there is one', () {
        // A declined-with-alternative should sort and display against the time
        // being proposed, not the one that did not work.
        final declined = _appointment(
          status: AppointmentStatus.declined,
          proposedFor: DateTime(2026, 8, 13, 14),
        );

        expect(declined.effectiveTime, DateTime(2026, 8, 13, 14));
      });
    });

    group('status', () {
      test('requested and confirmed are still going to happen', () {
        expect(AppointmentStatus.requested.isOpen, isTrue);
        expect(AppointmentStatus.confirmed.isOpen, isTrue);
      });

      test('declined, cancelled and completed are not', () {
        expect(AppointmentStatus.declined.isOpen, isFalse);
        expect(AppointmentStatus.cancelled.isOpen, isFalse);
        expect(AppointmentStatus.completed.isOpen, isFalse);
      });

      test('only a request is waiting on the doctor', () {
        expect(
          AppointmentStatus.values.where((s) => s.needsDoctor),
          <AppointmentStatus>[AppointmentStatus.requested],
        );
      });
    });

    group('copyWith', () {
      test('changes the status and keeps everything else', () {
        final confirmed = _appointment(patientName: 'Maria P')
            .copyWith(status: AppointmentStatus.confirmed);

        expect(confirmed.status, AppointmentStatus.confirmed);
        expect(confirmed.patientName, 'Maria P');
        expect(confirmed.patientNote, 'Tremor has been worse this week.');
        expect(confirmed.requestedFor, DateTime(2026, 8, 12, 10));
      });
    });
  });
}
