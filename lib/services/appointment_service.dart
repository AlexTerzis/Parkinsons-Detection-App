import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';

/// Reading appointments, and the transitions that are not a booking.
///
/// Kept apart from `ReportsService`, which is about reports and the notes
/// doctors write against them. An appointment is a different relationship with
/// a different lifecycle, and folding it in would make that class the place
/// where everything doctor-shaped ends up.
///
/// Making and cancelling an appointment live in [AvailabilityService] instead,
/// because both also move a slot on the doctor's calendar and the two writes
/// have to happen together. What is left here reads appointments and answers
/// the requests written under the older flow.
///
/// # Who may do what
///
/// The security rules let either party read and update an appointment they are
/// part of; **which transitions each side may make is enforced here**, not in
/// the rules. Writing a status state machine in rules is a great deal of
/// complexity for a single trusted client, and it would still have to be
/// duplicated here to give a decent error. If a second client is ever written
/// against this data, that trade-off has to be revisited.
class AppointmentService {
  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('appointments');

  /// Everything this patient has booked, soonest first.
  Stream<List<Appointment>> watchForPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('requestedFor', descending: true)
        .snapshots()
        .map(_toList);
  }

  /// Everything booked with this doctor, soonest first.
  Stream<List<Appointment>> watchForDoctor(String doctorId) {
    return _col
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('requestedFor', descending: true)
        .snapshots()
        .map(_toList);
  }

  List<Appointment> _toList(QuerySnapshot<Map<String, dynamic>> snap) => snap
      .docs
      .map((d) => Appointment.fromJson(d.data(), d.id))
      .toList(growable: false);

  /// Whether [status] is something a doctor may set by answering a request.
  ///
  /// Only `confirmed` and `declined` are the doctor's to give by answering.
  /// Cancelling is `AvailabilityService.cancelBooking`, which also frees the
  /// time, and completion is [markCompleted]; anything else is rejected rather
  /// than written.
  ///
  /// Pure and static so the rule can be tested without a Firestore instance —
  /// this project has no Firestore fake, and the rule is the part worth
  /// pinning. Cancelling and completing are separate operations with separate
  /// meanings, and folding them in here would make [respond] the one door every
  /// transition goes through with nothing to tell them apart.
  static bool isDoctorResponse(AppointmentStatus status) =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.declined;

  Future<void> respond({
    required String appointmentId,
    required AppointmentStatus status,
    String? doctorMessage,
    DateTime? proposedFor,
  }) async {
    if (!isDoctorResponse(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'A doctor may only confirm or decline; use cancel() or markCompleted().',
      );
    }

    await _col.doc(appointmentId).update(<String, dynamic>{
      'status': status.name,
      if (doctorMessage != null) 'doctorMessage': doctorMessage,
      if (proposedFor != null) 'proposedFor': Timestamp.fromDate(proposedFor),
    });
  }

  Future<void> markCompleted(String appointmentId) {
    return _col.doc(appointmentId).update(<String, dynamic>{
      'status': AppointmentStatus.completed.name,
    });
  }
}
