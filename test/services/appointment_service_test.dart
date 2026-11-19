import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/appointment.dart';
import 'package:parkinsondetetion/services/appointment_service.dart';

/// # Why there is no Firestore round-trip here
///
/// This project has no Firestore test double — `fake_cloud_firestore` is not a
/// dependency, and no other service in the repo is tested against the database
/// either. Rather than add a package for one test file, what is pinned here is
/// the rule that does not need one: which transitions belong to the doctor's
/// answer. Serialization, the other half of the risk, is covered against the
/// real shapes in `test/models/appointment_test.dart`.
///
/// The gap that leaves is the queries, which are only exercised on a device.
void main() {
  group('AppointmentService - what a doctor may answer', () {
    test('confirming and declining are the doctor\'s to give', () {
      expect(
        AppointmentService.isDoctorResponse(AppointmentStatus.confirmed),
        isTrue,
      );
      expect(
        AppointmentService.isDoctorResponse(AppointmentStatus.declined),
        isTrue,
      );
    });

    test('cancelling, completing and requesting are not', () {
      // Each of these is a separate operation with a separate meaning.
      // Reaching them through respond() would make it the one door every
      // transition goes through, with nothing left to tell them apart —
      // cancelling in particular also has to free the slot the appointment
      // was holding, which respond() knows nothing about.
      for (final status in <AppointmentStatus>[
        AppointmentStatus.cancelled,
        AppointmentStatus.completed,
        AppointmentStatus.requested,
      ]) {
        expect(
          AppointmentService.isDoctorResponse(status),
          isFalse,
          reason: '$status should not be reachable through respond()',
        );
      }
    });

    test('every status is accounted for', () {
      // Guards a status being added later without anyone deciding whether the
      // doctor may set it by answering.
      final answerable = AppointmentStatus.values
          .where(AppointmentService.isDoctorResponse)
          .toList();

      expect(answerable, <AppointmentStatus>[
        AppointmentStatus.confirmed,
        AppointmentStatus.declined,
      ]);
    });
  });

  group('which appointments leaving a doctor should cancel', () {
    test('the open ones, and only those', () {
      // `AvailabilityService.cancelOpenBetween` selects on this, so it is worth
      // pinning apart from the query it drives.
      final open =
          AppointmentStatus.values.where((s) => s.isOpen).toList();

      expect(open, <AppointmentStatus>[
        AppointmentStatus.requested,
        AppointmentStatus.confirmed,
      ]);
    });
  });
}
