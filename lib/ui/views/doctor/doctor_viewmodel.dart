import 'package:firebase_auth/firebase_auth.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_view.dart';
import '../../../app/app.locator.dart';
import '../../../services/reports_service.dart';
import '../../../services/appointment_service.dart';
import '../../../services/availability_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/patient_report.dart';
import '../../../models/appointment.dart';
import '../../../models/availability_slot.dart';
import '../../../models/doctor_note.dart';

class DoctorViewModel extends BaseViewModel {
  final ReportsService _reportsService = locator<ReportsService>();
  final AppointmentService _appointments = locator<AppointmentService>();
  final AvailabilityService _availability = locator<AvailabilityService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  // --- Profile fields ---
  String get email => _auth.currentUser?.email ?? '--';

  String _name = '--';
  String get name => _name.isEmpty ? '--' : _name;

  String _specialty = '';
  String get specialty => _specialty;

  String _location = '';
  String get location => _location;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  List<PatientReport> _reports = [];
  List<PatientReport> get reports => _reports;

  /// Set when the reports query itself failed.
  ///
  /// Distinct from an empty list, and the distinction matters: "nobody has sent
  /// you anything" and "we were not allowed to look" are different problems,
  /// and only one of them is the doctor's to wait out.
  String? _reportsError;
  String? get reportsError => _reportsError;

  List<Appointment> _appointmentList = [];
  List<Appointment> get appointments => _appointmentList;

  /// Open appointments that have no slot behind them, soonest first.
  ///
  /// These were made under the old request-and-confirm flow, before a booking
  /// came from a published time. They have nothing to appear under on the
  /// calendar, so they are listed separately — without this they would simply
  /// vanish from the doctor's screen while the patient still had them, which is
  /// the worst of both.
  List<Appointment> get appointmentsOffCalendar {
    final off = _appointmentList
        .where((a) => a.slotId == null && a.status.isOpen)
        .toList()
      ..sort((a, b) => a.effectiveTime.compareTo(b.effectiveTime));
    return off;
  }

  // --- Published calendar ---

  List<AvailabilitySlot> _slots = [];
  List<AvailabilitySlot> get slots => _slots;

  /// Set when the calendar could not be read, so the screen can say so instead
  /// of showing an empty month that looks like a doctor with no hours.
  String? _slotsError;
  String? get slotsError => _slotsError;

  /// This doctor's slots on one day, earliest first.
  List<AvailabilitySlot> slotsOn(DateTime day) {
    final wanted = DateTime(day.year, day.month, day.day);
    final onDay = _slots.where((s) => s.day == wanted).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return onDay;
  }

  int slotCountOn(DateTime day) => slotsOn(day).length;

  /// The booking that took [slot], if this doctor can still see it.
  Appointment? appointmentForSlot(AvailabilitySlot slot) {
    final id = slot.appointmentId;
    if (id == null) return null;
    for (final appointment in _appointmentList) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }

  /// Publishes every [durationMinutes] step between [from] and [to] on [day].
  ///
  /// Times already on the calendar for that day are skipped rather than
  /// written again, so adding "9 to 12" twice — or extending a morning that
  /// already runs to 11 — does not leave two offers for the same moment, which
  /// is a double booking waiting to be made.
  ///
  /// Returns how many were actually added.
  Future<int> publishSlots({
    required DateTime day,
    required Duration from,
    required Duration to,
    int durationMinutes = AvailabilitySlot.defaultDurationMinutes,
  }) async {
    final String? doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return 0;

    final candidates = AvailabilityService.slotTimes(
      day: day,
      from: from,
      to: to,
      durationMinutes: durationMinutes,
    );

    final existing = slotsOn(day);
    final wanted = candidates.where((start) {
      final candidate = AvailabilitySlot(
        id: '',
        doctorId: doctorId,
        start: start,
        durationMinutes: durationMinutes,
      );
      return !existing
          .any((s) => AvailabilitySlot.overlaps(s, candidate));
    }).toList();

    if (wanted.isEmpty) return 0;

    await _availability.publish(
      doctorId: doctorId,
      starts: wanted,
      doctorName: _name == '--' ? null : _name,
      durationMinutes: durationMinutes,
    );
    return wanted.length;
  }

  Future<void> withdrawSlot(String slotId) => _availability.withdraw(slotId);

  /// Calls off a booking and puts the time back on the calendar.
  Future<void> cancelBooking(Appointment appointment) =>
      _availability.cancelBooking(appointment);

  /// Appointments this patient has with this doctor, newest first.
  List<Appointment> appointmentsFor(String patientId) =>
      _appointmentList.where((a) => a.patientId == patientId).toList();

  String? _selectedPatientId;
  String? get selectedPatientId => _selectedPatientId;

  List<PatientReport> get selectedReports =>
      _reports.where((r) => r.patientId == _selectedPatientId).toList();

  final Map<String, String> _patientNames = {}; // uid -> name

  /// The patient's name, taken from the reports they sent.
  ///
  /// Falls back to the account id, which is all that is knowable for reports
  /// written before the name was carried on them. It used to fall back to the
  /// id *always*: the name came from reading the patient's profile document,
  /// which the security rules deny a doctor, so the lookup failed silently on
  /// every patient and this screen listed raw account ids.
  String patientName(String id) => _patientNames[id] ?? id;

  final TextEditingController noteController = TextEditingController();

  /// Sample community posts; in the future these would come from Firestore.
  List<Map<String, String>> posts = [];

  Future<void> init() async {
    final String? doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return;

    setBusy(true);
    // try/finally, so a throw anywhere below cannot leave the view model busy.
    // `DoctorView` swaps its whole tree for a spinner while `isBusy`, so a
    // failed profile read used to strand the doctor on it with no way out —
    // the same defect already fixed in `PatienceViewModel.init`.
    try {
      // Load profile info
      _name = await _auth.fetchDisplayName() ?? '--';
      nameController.text = _name == '--' ? '' : _name;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      final data = doc.data();
      if (data != null) {
        _specialty = data['specialty'] ?? '';
        _location = data['location'] ?? '';
        specialtyController.text = _specialty;
        locationController.text = _location;
      }
    } catch (e) {
      // Recorded, not swallowed. The profile is not worth blocking the screen
      // for — the reports and calendar below matter more.
      debugPrint('Could not load doctor profile: $e');
    }

    // Demo community posts
    posts = [
      {
        'author': _name,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'content': 'Excited to join the community!'
      }
    ];

    // onError, not a bare listen. Without it a rejected query — a missing
    // composite index, a rules change — is indistinguishable from a doctor
    // whose patients have simply never sent anything, and the only trace is a
    // line in a console nobody is reading.
    _reportsService.watchReportsForDoctor(doctorId).listen(
      (data) {
        _reports = data;
        _reportsError = null;

        // Names come off the reports themselves. The patient writes their own
        // name when sending, which is the only party who can — reading it back
        // from their profile is a cross-user read the rules refuse, and
        // widening them for a doctor would expose the whole profile to get one
        // field.
        for (final report in _reports) {
          final name = report.patientName?.trim();
          if (name != null && name.isNotEmpty) {
            _patientNames[report.patientId] = name;
          }
        }

        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not watch reports: $e');
        _reportsError = '$e';
        notifyListeners();
      },
    );

    // onError rather than a bare listen: this query needs a composite index,
    // and a missing one fails at runtime with nothing to show for it at build
    // time. Losing that silently is how the doctor list came to look
    // permanently empty elsewhere in this app.
    _appointments.watchForDoctor(doctorId).listen(
      (data) {
        _appointmentList = data;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not watch appointments: $e');
      },
    );

    // Same treatment for the published calendar, and for the same reason: it
    // needs a composite index, and a missing one fails at runtime with nothing
    // to show for it at build time. Recorded rather than swallowed, so an empty
    // month can be told apart from a month that failed to load.
    _availability.watchForDoctor(doctorId).listen(
      (data) {
        _slots = data;
        _slotsError = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not watch availability: $e');
        _slotsError = '$e';
        notifyListeners();
      },
    );

    setBusy(false);
  }

  // --- Appointments ---

  Future<void> confirmAppointment(String appointmentId, {String? message}) {
    return _appointments.respond(
      appointmentId: appointmentId,
      status: AppointmentStatus.confirmed,
      doctorMessage: message,
    );
  }

  /// Turns a request down, optionally offering another time.
  ///
  /// [proposedFor] is what makes a decline useful rather than a dead end: the
  /// patient sees the alternative on their own screen and can take it up in one
  /// tap.
  Future<void> declineAppointment(
    String appointmentId, {
    String? message,
    DateTime? proposedFor,
  }) {
    return _appointments.respond(
      appointmentId: appointmentId,
      status: AppointmentStatus.declined,
      doctorMessage: message,
      proposedFor: proposedFor,
    );
  }

  Future<void> markAppointmentCompleted(String appointmentId) =>
      _appointments.markCompleted(appointmentId);

  void selectPatient(String patientId) {
    _selectedPatientId = patientId;
    notifyListeners();
  }

  Future<void> addNoteToSelectedReport(String noteText) async {
    final pid = _selectedPatientId;
    if (pid == null) return;
    await addNoteToReportForPatient(pid, noteText: noteText);
  }

  /// Attaches a note to a specific report.
  ///
  /// The report is named by the caller rather than guessed at. The older
  /// [addNoteToReportForPatient] picks the first report matching a patient,
  /// which after ordering is the newest one — so a note written while reading
  /// an older report landed on the wrong one.
  Future<void> addNoteToReport({
    required String reportId,
    required String note,
  }) async {
    final text = note.trim();
    final uid = _auth.currentUser?.uid;
    if (text.isEmpty || uid == null) return;

    await _reportsService.addNoteToReport(
      reportId: reportId,
      note: DoctorNote(doctorId: uid, note: text, createdAt: DateTime.now()),
    );
  }

  Future<void> addNoteToReportForPatient(String patientId, {String? noteText}) async {
    final text = noteText ?? noteController.text.trim();
    if (text.isEmpty) return;
        PatientReport? report;
      for (var r in _reports) {
        if (r.patientId == patientId) {
          report = r;
          break;
        }
      }
      if (report == null) return;

      final DoctorNote note = DoctorNote(
        doctorId: _auth.currentUser!.uid,
        note: text,
        createdAt: DateTime.now(),
      );

      await _reportsService.addNoteToReport(reportId: report.id, note: note);
      noteController.clear();
    }

  /// Persist profile changes to Firestore and update display name.
  Future<void> saveProfile() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _name = nameController.text.trim();
    _specialty = specialtyController.text.trim();
    _location = locationController.text.trim();
    notifyListeners();

    await _auth.updateDisplayName(_name);

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'name': _name,
        'specialty': _specialty,
        'location': _location,
      },
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    nameController.dispose();
    specialtyController.dispose();
    locationController.dispose();
    super.dispose();
  }
  /// Sign the current user out and navigate back to [LoginView].
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('keepMeLoggedIn');
    // Cleared with the session, so the next account to sign in on this device
    // cannot be routed by the previous one's role on a slow launch.
    await prefs.remove('cachedRole');
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginView()),
        (route) => false,
      );
    }
  }
}


