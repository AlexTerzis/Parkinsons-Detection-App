import 'package:cloud_firestore/cloud_firestore.dart';

/// A time a doctor has published as available, and who (if anyone) took it.
///
/// This is the doctor's calendar. The patient does not propose a time and wait
/// to hear back — they see what is actually free and take it, and the booking
/// is settled the moment they do. That is the direction the app used to run in
/// reverse, with the patient guessing at a time and the doctor confirming or
/// countering, which left every booking sitting in limbo until the doctor
/// happened to look.
///
/// # Why the patient's identity is not on an open slot
///
/// While [bookedBy] is null this document is readable by any signed-in user —
/// it has to be, or nobody could browse a calendar. So it must hold nothing
/// about a patient until there is a patient, and once there is, the security
/// rules narrow reads to the two parties. Everything else about the booking —
/// the reason for the visit, the notes, the cancellation — lives on the
/// `Appointment` the booking creates, which was never publicly readable.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.doctorId,
    required this.start,
    required this.durationMinutes,
    this.doctorName,
    this.bookedBy,
    this.appointmentId,
  });

  final String id;
  final String doctorId;

  /// The doctor's name when the slot was published, so a patient browsing a
  /// calendar does not need a second read per slot to know whose it is.
  final String? doctorName;

  /// When the appointment would start.
  final DateTime start;

  final int durationMinutes;

  /// The patient who took this slot, or null while it is still open.
  ///
  /// Written explicitly as null rather than left off the document: Firestore
  /// does not return documents missing a field for `where(field, isEqualTo:
  /// null)`, so an absent `bookedBy` would make a slot invisible to the very
  /// query that looks for free ones.
  final String? bookedBy;

  /// The `appointments` document this slot became once booked.
  final String? appointmentId;

  bool get isOpen => bookedBy == null;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  /// Whether the slot has already gone by. Judged on [end], so a patient is not
  /// shown a slot that started five minutes ago as though it were still theirs
  /// to take.
  bool isPastAt(DateTime now) => !end.isAfter(now);

  /// The calendar day this slot falls on, in the reader's own time zone.
  ///
  /// Grouping by anything else puts an evening appointment on the wrong day for
  /// anyone east or west of where the document was written.
  DateTime get day {
    final local = start.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  AvailabilitySlot copyWith({
    String? bookedBy,
    String? appointmentId,
    bool clearBooking = false,
  }) {
    return AvailabilitySlot(
      id: id,
      doctorId: doctorId,
      doctorName: doctorName,
      start: start,
      durationMinutes: durationMinutes,
      bookedBy: clearBooking ? null : (bookedBy ?? this.bookedBy),
      appointmentId: clearBooking ? null : (appointmentId ?? this.appointmentId),
    );
  }

  factory AvailabilitySlot.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return AvailabilitySlot(
      id: documentId,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String?,
      start: (json['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // 30 minutes is the default a slot is published with; documents written
      // before the field existed read back the same way they were shown.
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      bookedBy: json['bookedBy'] as String?,
      appointmentId: json['appointmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      'start': Timestamp.fromDate(start),
      'durationMinutes': durationMinutes,
      // Always written, never omitted — see [bookedBy].
      'bookedBy': bookedBy,
      'appointmentId': appointmentId,
    };
  }

  /// The default length of a published slot.
  static const int defaultDurationMinutes = 30;

  /// Whether [candidate] would land on top of an existing slot.
  ///
  /// Publishing the same time twice is easy to do by accident when adding a
  /// morning's worth of slots, and two overlapping offers for one doctor is a
  /// double-booking waiting to happen.
  static bool overlaps(AvailabilitySlot a, AvailabilitySlot b) =>
      a.start.isBefore(b.end) && b.start.isBefore(a.end);
}
