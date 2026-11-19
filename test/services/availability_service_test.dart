import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/models/availability_slot.dart';
import 'package:parkinsondetetion/services/availability_service.dart';

/// # Why there is no Firestore round-trip here
///
/// This project has no Firestore test double — `fake_cloud_firestore` is not a
/// dependency, and no other service in the repo is tested against the database.
/// What is pinned here is the arithmetic that does not need one: which times a
/// published range comes to, and which day each slot lands on.
///
/// The gap that leaves is the booking transaction in `book`, and the paired
/// write in `cancelBooking`. Those are only exercised on a device. The rule
/// they enforce — that a slot re-read inside the transaction must still be open
/// — is the reason they are transactions at all, and it cannot be checked
/// without a database that can produce the race.
AvailabilitySlot slotAt(DateTime start, {int durationMinutes = 30}) {
  return AvailabilitySlot(
    id: 'slot-${start.millisecondsSinceEpoch}',
    doctorId: 'doc-1',
    start: start,
    durationMinutes: durationMinutes,
  );
}

void main() {
  group('slotTimes', () {
    test('cuts a morning into appointments', () {
      final times = AvailabilityService.slotTimes(
        day: DateTime(2026, 8, 12),
        from: const Duration(hours: 9),
        to: const Duration(hours: 11),
        durationMinutes: 30,
      );

      expect(times, <DateTime>[
        DateTime(2026, 8, 12, 9, 0),
        DateTime(2026, 8, 12, 9, 30),
        DateTime(2026, 8, 12, 10, 0),
        DateTime(2026, 8, 12, 10, 30),
      ]);
    });

    test('never lets a slot run past the end of the window', () {
      // 9:00 to 10:20 at 30 minutes is two appointments, not three: the third
      // would finish at 10:30, past the time the doctor said they were free.
      final times = AvailabilityService.slotTimes(
        day: DateTime(2026, 8, 12),
        from: const Duration(hours: 9),
        to: const Duration(hours: 10, minutes: 20),
        durationMinutes: 30,
      );

      expect(times, hasLength(2));
      expect(times.last, DateTime(2026, 8, 12, 9, 30));
    });

    test('ignores the time on the day it is given', () {
      // The day comes from a calendar cell, which may carry a time; the window
      // is what decides the hours.
      final times = AvailabilityService.slotTimes(
        day: DateTime(2026, 8, 12, 17, 42),
        from: const Duration(hours: 9),
        to: const Duration(hours: 9, minutes: 30),
        durationMinutes: 30,
      );

      expect(times, <DateTime>[DateTime(2026, 8, 12, 9, 0)]);
    });

    test('an empty or backwards window publishes nothing', () {
      DateTime day() => DateTime(2026, 8, 12);

      expect(
        AvailabilityService.slotTimes(
          day: day(),
          from: const Duration(hours: 11),
          to: const Duration(hours: 9),
          durationMinutes: 30,
        ),
        isEmpty,
      );
      expect(
        AvailabilityService.slotTimes(
          day: day(),
          from: const Duration(hours: 9),
          to: const Duration(hours: 9),
          durationMinutes: 30,
        ),
        isEmpty,
      );
    });

    test('a window shorter than one appointment publishes nothing', () {
      expect(
        AvailabilityService.slotTimes(
          day: DateTime(2026, 8, 12),
          from: const Duration(hours: 9),
          to: const Duration(hours: 9, minutes: 20),
          durationMinutes: 30,
        ),
        isEmpty,
      );
    });

    test('a zero or negative duration publishes nothing rather than looping', () {
      // Guards the loop: stepping by nothing never reaches the end of the
      // window, so without this the doctor's app would hang on publish.
      expect(
        AvailabilityService.slotTimes(
          day: DateTime(2026, 8, 12),
          from: const Duration(hours: 9),
          to: const Duration(hours: 11),
          durationMinutes: 0,
        ),
        isEmpty,
      );
      expect(
        AvailabilityService.slotTimes(
          day: DateTime(2026, 8, 12),
          from: const Duration(hours: 9),
          to: const Duration(hours: 11),
          durationMinutes: -30,
        ),
        isEmpty,
      );
    });

    test('published times are contiguous and non-overlapping', () {
      // What the calendar promises: back to back, with no moment offered twice.
      final times = AvailabilityService.slotTimes(
        day: DateTime(2026, 8, 12),
        from: const Duration(hours: 9),
        to: const Duration(hours: 12),
        durationMinutes: 20,
      );
      final slots =
          times.map((t) => slotAt(t, durationMinutes: 20)).toList();

      for (var i = 1; i < slots.length; i++) {
        expect(
          AvailabilitySlot.overlaps(slots[i - 1], slots[i]),
          isFalse,
          reason: 'slot $i overlaps the one before it',
        );
        expect(slots[i].start, slots[i - 1].end);
      }
    });
  });

  group('groupByDay', () {
    test('puts each slot on its own day, in time order', () {
      final monday = DateTime(2026, 8, 10, 15);
      final slots = <AvailabilitySlot>[
        slotAt(DateTime(2026, 8, 10, 11)),
        slotAt(DateTime(2026, 8, 11, 9)),
        slotAt(DateTime(2026, 8, 10, 9)),
      ];

      final byDay = AvailabilityService.groupByDay(slots);

      expect(byDay.keys, hasLength(2));
      final mondaySlots = byDay[DateTime(monday.year, monday.month, 10)]!;
      expect(mondaySlots, hasLength(2));
      // Sorted, so the calendar does not list 11:00 above 9:00 just because
      // that is the order Firestore happened to return.
      expect(mondaySlots.first.start.hour, 9);
      expect(mondaySlots.last.start.hour, 11);
    });

    test('nothing in, nothing out', () {
      expect(AvailabilityService.groupByDay(const []), isEmpty);
    });

    test('keys match AvailabilitySlot.day, so calendar lookups hit', () {
      // The calendar looks slots up by the day cell it drew. If these two ever
      // disagree, every day shows as empty with no error to say why.
      final slot = slotAt(DateTime(2026, 8, 12, 16, 45));
      final byDay = AvailabilityService.groupByDay(<AvailabilitySlot>[slot]);

      expect(byDay[slot.day], isNotNull);
      expect(byDay[slot.day], hasLength(1));
    });
  });
}
