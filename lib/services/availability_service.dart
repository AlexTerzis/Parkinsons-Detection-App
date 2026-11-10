import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/availability_slot.dart';

/// Raised when a slot cannot be taken because someone else got there first, or
/// because the doctor withdrew it.
///
/// A named exception rather than a bare `false` return: the two cases read
/// differently to a patient staring at a calendar, and both need saying out
/// loud instead of the tap appearing to do nothing.
class SlotUnavailableException implements Exception {
  const SlotUnavailableException.taken() : alreadyBooked = true;
  const SlotUnavailableException.withdrawn() : alreadyBooked = false;

  /// True when another patient booked it; false when the doctor removed it.
  final bool alreadyBooked;

  @override
  String toString() => alreadyBooked
      ? 'That time has just been booked by someone else.'
      : 'That time is no longer offered.';
}

/// The doctor's published calendar, and the booking of times on it.
///
/// Separate from [AppointmentService] because the two hold different things for
/// different audiences. A slot is an offer with no patient on it, readable by
/// anyone signed in so a calendar can be browsed at all; an appointment is the
/// booking, private to the two people in it. Keeping them in one collection
/// would mean a document that is public one moment and confidential the next,
/// with the security rules having to change shape underneath it.
class AvailabilityService {
  AvailabilityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _slots =>
      _firestore.collection('availability');

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  /// Everything on this doctor's calendar from [from] onward, booked or not.
  ///
  /// [from] is not optional in spirit even though it has a default: without a
  /// lower bound this grows without limit as the months go by, and the doctor
  /// pays for reading every slot they ever published.
  Stream<List<AvailabilitySlot>> watchForDoctor(
    String doctorId, {
    DateTime? from,
  }) {
    final lowerBound = from ?? _defaultLowerBound();
    return _slots
        .where('doctorId', isEqualTo: doctorId)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .orderBy('start')
        .snapshots()
        .map(_toList);
  }

  /// The times still free with this doctor, soonest first.
  ///
  /// The `bookedBy == null` filter is not decoration. The security rules let any
  /// signed-in user read an *open* slot and nobody but the two parties read a
  /// booked one, and a Firestore query is rejected outright unless the rules can
  /// prove every document it would return is readable. Dropping this clause does
  /// not return more rows — it returns none.
  Stream<List<AvailabilitySlot>> watchOpenFor(
    String doctorId, {
    DateTime? from,
  }) {
    final lowerBound = from ?? DateTime.now();
    return _slots
        .where('doctorId', isEqualTo: doctorId)
        .where('bookedBy', isNull: true)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .orderBy('start')
        .snapshots()
        .map(_toList);
  }

  List<AvailabilitySlot> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs
          .map((d) => AvailabilitySlot.fromJson(d.data(), d.id))
          .toList(growable: false);

  /// A month back, so the doctor can still see what happened recently without
  /// the query reaching all the way to the beginning.
  static DateTime _defaultLowerBound() =>
      DateTime.now().subtract(const Duration(days: 31));

  /// Publishes times the doctor is free.
  ///
  /// Written as one batch: adding a morning's worth of slots is a single act,
  /// and half a morning appearing on the calendar is worse than none of it.
  Future<void> publish({
    required String doctorId,
    required List<DateTime> starts,
    String? doctorName,
    int durationMinutes = AvailabilitySlot.defaultDurationMinutes,
  }) async {
    if (starts.isEmpty) return;

    final batch = _firestore.batch();
    for (final start in starts) {
      final slot = AvailabilitySlot(
        id: '',
        doctorId: doctorId,
        doctorName: doctorName,
        start: start,
        durationMinutes: durationMinutes,
      );
      batch.set(_slots.doc(), slot.toJson());
    }
    await batch.commit();
  }

  /// Takes a published time off the calendar.
  ///
  /// The rules refuse this for a slot that is booked, which is deliberate: a
  /// patient is expecting that appointment, so it has to be cancelled — which
  /// tells them — rather than deleted out from under them.
  Future<void> withdraw(String slotId) => _slots.doc(slotId).delete();

  /// Books [slot] for a patient, creating the appointment in the same breath.
  ///
  /// The read-then-write happens inside a transaction because two patients can
  /// be looking at the same free slot at the same time. Checking `isOpen` on
  /// the copy already in memory would let both of them pass the check and both
  /// write, and the second would silently take the first one's appointment.
  /// Re-reading inside the transaction makes the loser fail instead, with
  /// [SlotUnavailableException] to say so.
  ///
  /// Throws [SlotUnavailableException] if the slot was taken or withdrawn.
  Future<Appointment> book({
    required AvailabilitySlot slot,
    required String patientId,
    String? patientName,
    String? patientNote,
  }) async {
    final slotRef = _slots.doc(slot.id);
    final appointmentRef = _appointments.doc();

    final appointment = Appointment(
      id: appointmentRef.id,
      patientId: patientId,
      doctorId: slot.doctorId,
      patientName: patientName,
      doctorName: slot.doctorName,
      requestedFor: slot.start,
      requestedAt: DateTime.now(),
      // Confirmed on creation. The doctor offered this time, so there is
      // nothing left for them to agree to.
      status: AppointmentStatus.confirmed,
      patientNote: patientNote,
      slotId: slot.id,
      durationMinutes: slot.durationMinutes,
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(slotRef);
      if (!snapshot.exists) {
        throw const SlotUnavailableException.withdrawn();
      }

      final current = AvailabilitySlot.fromJson(snapshot.data()!, snapshot.id);
      if (!current.isOpen) {
        throw const SlotUnavailableException.taken();
      }

      transaction.set(appointmentRef, appointment.toJson());
      transaction.update(slotRef, <String, dynamic>{
        'bookedBy': patientId,
        'appointmentId': appointmentRef.id,
      });
    });

    return appointment;
  }

  /// Cancels a booking and puts its time back on the calendar.
  ///
  /// Both halves in one transaction, so the calendar cannot end up with a slot
  /// blocked by an appointment that no longer exists — which is the state a
  /// cancel-then-release pair leaves behind whenever the second call fails.
  ///
  /// Appointments from the old flow have no [Appointment.slotId]; those are
  /// simply cancelled, with nothing to give back.
  Future<void> cancelBooking(Appointment appointment) async {
    final appointmentRef = _appointments.doc(appointment.id);
    final slotId = appointment.slotId;

    if (slotId == null) {
      await appointmentRef.update(<String, dynamic>{
        'status': AppointmentStatus.cancelled.name,
      });
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final slotSnapshot = await transaction.get(_slots.doc(slotId));

      transaction.update(appointmentRef, <String, dynamic>{
        'status': AppointmentStatus.cancelled.name,
      });

      // The slot may have been deleted, or already handed to someone else if
      // this appointment was cancelled twice. Only release what this
      // appointment still holds.
      if (!slotSnapshot.exists) return;
      final slot =
          AvailabilitySlot.fromJson(slotSnapshot.data()!, slotSnapshot.id);
      if (slot.appointmentId != appointment.id) return;

      transaction.update(slotSnapshot.reference, <String, dynamic>{
        'bookedBy': null,
        'appointmentId': null,
      });
    });
  }

  /// Cancels every appointment still open between a patient and a doctor, and
  /// frees the times they were holding.
  ///
  /// Used when a patient leaves their doctor. Reports already sent stay where
  /// they are — they record something genuinely shared — but a future
  /// appointment with a doctor you have left should not quietly survive, and
  /// the doctor should get those hours back rather than have them blocked by
  /// someone who is no longer their patient.
  ///
  /// One batch, so leaving cannot half-succeed and strand some appointments
  /// open or some slots held.
  ///
  /// Returns how many appointments were cancelled.
  Future<int> cancelOpenBetween({
    required String patientId,
    required String doctorId,
  }) async {
    final snapshot = await _appointments
        .where('patientId', isEqualTo: patientId)
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final open = snapshot.docs
        .map((d) => Appointment.fromJson(d.data(), d.id))
        .where((a) => a.status.isOpen)
        .toList();

    if (open.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final appointment in open) {
      batch.update(_appointments.doc(appointment.id), <String, dynamic>{
        'status': AppointmentStatus.cancelled.name,
      });

      // Appointments from the old request-and-confirm flow have no slot to
      // give back.
      final slotId = appointment.slotId;
      if (slotId == null) continue;
      batch.update(_slots.doc(slotId), <String, dynamic>{
        'bookedBy': null,
        'appointmentId': null,
      });
    }
    await batch.commit();
    return open.length;
  }

  /// Groups slots by the local calendar day they fall on.
  ///
  /// Pure and static so the calendar's day markers can be tested without a
  /// Firestore instance — this project has no Firestore fake, and how a slot
  /// lands on a day is the part with a time-zone bug in it waiting to happen.
  static Map<DateTime, List<AvailabilitySlot>> groupByDay(
    Iterable<AvailabilitySlot> slots,
  ) {
    final byDay = <DateTime, List<AvailabilitySlot>>{};
    for (final slot in slots) {
      byDay.putIfAbsent(slot.day, () => <AvailabilitySlot>[]).add(slot);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return byDay;
  }

  /// The times a doctor would be publishing by asking for slots every
  /// [durationMinutes] between [from] and [to] on [day].
  ///
  /// Pure, so "9 to 12, every 30 minutes" can be checked without a database.
  /// Stops before [to] rather than at it, so a slot never runs past the end of
  /// the window the doctor said they were free.
  static List<DateTime> slotTimes({
    required DateTime day,
    required Duration from,
    required Duration to,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0 || to <= from) return const <DateTime>[];

    final midnight = DateTime(day.year, day.month, day.day);
    final step = Duration(minutes: durationMinutes);
    final times = <DateTime>[];

    for (var at = from; at + step <= to; at += step) {
      times.add(midnight.add(at));
    }
    return times;
  }
}
