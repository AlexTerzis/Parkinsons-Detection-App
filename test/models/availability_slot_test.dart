import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/availability_slot.dart';

AvailabilitySlot slotAt(
  DateTime start, {
  int durationMinutes = 30,
  String? bookedBy,
  String? appointmentId,
}) {
  return AvailabilitySlot(
    id: 'slot-1',
    doctorId: 'doc-1',
    doctorName: 'Dr Who',
    start: start,
    durationMinutes: durationMinutes,
    bookedBy: bookedBy,
    appointmentId: appointmentId,
  );
}

void main() {
  group('AvailabilitySlot serialization', () {
    test('survives a round trip', () {
      final original = slotAt(
        DateTime(2026, 8, 12, 10, 30),
        durationMinutes: 45,
        bookedBy: 'patient-7',
        appointmentId: 'appt-3',
      );

      final restored =
          AvailabilitySlot.fromJson(original.toJson(), original.id);

      expect(restored.doctorId, original.doctorId);
      expect(restored.doctorName, original.doctorName);
      expect(restored.start, original.start);
      expect(restored.durationMinutes, 45);
      expect(restored.bookedBy, 'patient-7');
      expect(restored.appointmentId, 'appt-3');
    });

    test('writes bookedBy as an explicit null while open', () {
      // Not a style point. Firestore does not return documents that are missing
      // a field for `where(field, isEqualTo: null)`, so an omitted `bookedBy`
      // would make an open slot invisible to the query that looks for free
      // ones — the calendar would come back empty with nothing to explain it.
      final json = slotAt(DateTime(2026, 8, 12, 9)).toJson();

      expect(json.containsKey('bookedBy'), isTrue);
      expect(json['bookedBy'], isNull);
      expect(json.containsKey('appointmentId'), isTrue);
    });

    test('a document written before durationMinutes existed reads as 30', () {
      final restored = AvailabilitySlot.fromJson(<String, dynamic>{
        'doctorId': 'doc-1',
        'start': Timestamp.fromDate(DateTime(2026, 8, 12, 9)),
        'bookedBy': null,
      }, 'slot-legacy');

      expect(
        restored.durationMinutes,
        AvailabilitySlot.defaultDurationMinutes,
      );
    });
  });

  group('open and past', () {
    test('a slot with nobody on it is open', () {
      expect(slotAt(DateTime(2026, 8, 12, 9)).isOpen, isTrue);
      expect(slotAt(DateTime(2026, 8, 12, 9), bookedBy: 'p').isOpen, isFalse);
    });

    test('a slot is past only once it has finished', () {
      final slot = slotAt(DateTime(2026, 8, 12, 9), durationMinutes: 30);

      // Ten minutes in: started, but still this appointment.
      expect(slot.isPastAt(DateTime(2026, 8, 12, 9, 10)), isFalse);
      // Exactly at the end counts as over, so a finished slot is never offered.
      expect(slot.isPastAt(DateTime(2026, 8, 12, 9, 30)), isTrue);
      expect(slot.isPastAt(DateTime(2026, 8, 12, 8, 59)), isFalse);
    });
  });

  group('which day a slot falls on', () {
    test('is the local calendar day, not the UTC one', () {
      // A slot stored as a UTC instant must land on the day the person reading
      // it would call it. Grouping on the UTC date puts an evening appointment
      // on tomorrow for anyone east of Greenwich, which is exactly the calendar
      // this app runs in.
      final utcEvening = DateTime.utc(2026, 8, 12, 23, 30);
      final slot = slotAt(utcEvening);
      final local = utcEvening.toLocal();

      expect(slot.day, DateTime(local.year, local.month, local.day));
    });

    test('has no time component', () {
      final day = slotAt(DateTime(2026, 8, 12, 16, 45)).day;

      expect(day.hour, 0);
      expect(day.minute, 0);
      expect(day.second, 0);
    });
  });

  group('overlap', () {
    test('two slots sharing any moment overlap', () {
      final nine = slotAt(DateTime(2026, 8, 12, 9), durationMinutes: 30);
      final quarterPast =
          slotAt(DateTime(2026, 8, 12, 9, 15), durationMinutes: 30);

      expect(AvailabilitySlot.overlaps(nine, quarterPast), isTrue);
      expect(AvailabilitySlot.overlaps(quarterPast, nine), isTrue);
    });

    test('back-to-back slots do not', () {
      // 9:00-9:30 and 9:30-10:00 is the normal shape of a published morning.
      // Treating them as overlapping would make publishing a run impossible.
      final first = slotAt(DateTime(2026, 8, 12, 9), durationMinutes: 30);
      final second = slotAt(DateTime(2026, 8, 12, 9, 30), durationMinutes: 30);

      expect(AvailabilitySlot.overlaps(first, second), isFalse);
    });

    test('a slot overlaps itself', () {
      final slot = slotAt(DateTime(2026, 8, 12, 9));
      expect(AvailabilitySlot.overlaps(slot, slot), isTrue);
    });
  });

  group('copyWith', () {
    test('clearBooking gives the slot back', () {
      final booked = slotAt(
        DateTime(2026, 8, 12, 9),
        bookedBy: 'patient-7',
        appointmentId: 'appt-3',
      );

      final released = booked.copyWith(clearBooking: true);

      expect(released.isOpen, isTrue);
      expect(released.appointmentId, isNull);
      expect(released.start, booked.start);
      expect(released.doctorId, booked.doctorId);
    });
  });
}
