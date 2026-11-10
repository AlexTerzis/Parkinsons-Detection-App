import 'package:cloud_firestore/cloud_firestore.dart';

import 'availability_slot.dart';

/// Where an appointment request has got to.
enum AppointmentStatus {
  /// The patient has asked; the doctor has not answered yet.
  requested,

  /// The doctor accepted the time the patient asked for.
  confirmed,

  /// The doctor cannot make it. [Appointment.doctorMessage] says why, and
  /// [Appointment.proposedFor] may carry an alternative.
  declined,

  /// Called off. Either side may do this, at any point before it happens.
  cancelled,

  /// It took place.
  completed,
}

extension AppointmentStatusInfo on AppointmentStatus {
  /// Whether this appointment is still going to happen, as far as anyone knows.
  bool get isOpen =>
      this == AppointmentStatus.requested || this == AppointmentStatus.confirmed;

  /// Whether it is waiting on the doctor.
  bool get needsDoctor => this == AppointmentStatus.requested;
}

/// One appointment between a patient and a doctor.
///
/// An appointment is now made by taking a time the doctor has already published
/// — see [AvailabilitySlot] — so a new one starts life already
/// [AppointmentStatus.confirmed] and [slotId] says which slot it came from.
/// Nothing needs confirming, because the doctor offered the time in the first
/// place.
///
/// The [AppointmentStatus.requested] and [AppointmentStatus.declined] states
/// belong to the older flow, where the patient guessed at a time and waited to
/// hear back. They are kept because documents written under it still exist and
/// must still render; nothing creates them any more.
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.requestedFor,
    required this.requestedAt,
    this.patientName,
    this.doctorName,
    this.status = AppointmentStatus.requested,
    this.patientNote,
    this.doctorMessage,
    this.proposedFor,
    this.slotId,
    this.durationMinutes = AvailabilitySlot.defaultDurationMinutes,
  });

  final String id;
  final String patientId;
  final String doctorId;

  /// The patient's name, written onto the appointment when it is requested.
  ///
  /// Carried rather than looked up for the same reason it is carried on
  /// `PatientReport`: the security rules give each user access to their own
  /// profile only, so a doctor cannot read a patient's name, and widening that
  /// would expose a whole profile to obtain one field. The patient is the one
  /// creating the document, so they are the one who can supply it.
  final String? patientName;

  /// The doctor's name at the time of booking.
  ///
  /// A patient *can* read a doctor's profile, so this is not strictly needed —
  /// but storing it keeps the record readable if the doctor later changes their
  /// name, and means the list renders without a second lookup.
  final String? doctorName;

  /// When the patient would like to be seen.
  final DateTime requestedFor;

  /// When they asked.
  final DateTime requestedAt;

  final AppointmentStatus status;

  /// Why the patient wants to be seen.
  final String? patientNote;

  /// The doctor's reply — a reason for declining, or a note on the confirmation.
  final String? doctorMessage;

  /// A time the doctor suggested instead. Only meaningful when [status] is
  /// [AppointmentStatus.declined].
  final DateTime? proposedFor;

  /// The published slot this appointment was booked from.
  ///
  /// Null on appointments made under the old request-and-confirm flow, which
  /// had no slots to book from. Cancelling one that has a slot puts the time
  /// back on the doctor's calendar for someone else.
  final String? slotId;

  /// How long the appointment is, in minutes. Comes from the slot.
  final int durationMinutes;

  /// When the appointment ends, for display alongside its start.
  DateTime get endTime =>
      effectiveTime.add(Duration(minutes: durationMinutes));

  /// The time this appointment is actually for.
  ///
  /// The doctor's counter-offer wins when there is one, so a declined-with-
  /// alternative sorts and displays against the time being proposed rather than
  /// the one that did not work.
  DateTime get effectiveTime => proposedFor ?? requestedFor;

  /// What to show a doctor for this patient. Falls back to the account id for
  /// documents written before the name was carried.
  String get patientDisplayName {
    final name = patientName?.trim();
    return (name == null || name.isEmpty) ? patientId : name;
  }

  /// What to show a patient for this doctor.
  String get doctorDisplayName {
    final name = doctorName?.trim();
    return (name == null || name.isEmpty) ? doctorId : name;
  }

  Appointment copyWith({
    AppointmentStatus? status,
    String? doctorMessage,
    DateTime? proposedFor,
  }) {
    return Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      doctorName: doctorName,
      requestedFor: requestedFor,
      requestedAt: requestedAt,
      status: status ?? this.status,
      patientNote: patientNote,
      doctorMessage: doctorMessage ?? this.doctorMessage,
      proposedFor: proposedFor ?? this.proposedFor,
      slotId: slotId,
      durationMinutes: durationMinutes,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json, String documentId) {
    return Appointment(
      id: documentId,
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      patientName: json['patientName'] as String?,
      doctorName: json['doctorName'] as String?,
      requestedFor:
          (json['requestedFor'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestedAt:
          (json['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(json['status'] as String? ?? 'requested'),
      patientNote: json['patientNote'] as String?,
      doctorMessage: json['doctorMessage'] as String?,
      proposedFor: (json['proposedFor'] as Timestamp?)?.toDate(),
      slotId: json['slotId'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          AvailabilitySlot.defaultDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      if (patientName != null) 'patientName': patientName,
      if (doctorName != null) 'doctorName': doctorName,
      'requestedFor': Timestamp.fromDate(requestedFor),
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      if (patientNote != null) 'patientNote': patientNote,
      if (doctorMessage != null) 'doctorMessage': doctorMessage,
      if (proposedFor != null) 'proposedFor': Timestamp.fromDate(proposedFor!),
      if (slotId != null) 'slotId': slotId,
      'durationMinutes': durationMinutes,
    };
  }

  static AppointmentStatus _statusFromString(String value) {
    for (final status in AppointmentStatus.values) {
      if (status.name == value) return status;
    }
    return AppointmentStatus.requested;
  }
}
