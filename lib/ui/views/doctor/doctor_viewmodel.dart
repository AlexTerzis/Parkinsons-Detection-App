import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';

import '../../../app/app.locator.dart';
import '../../../services/reports_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/app_user.dart';
import '../../../models/patient_report.dart';
import '../../../models/doctor_note.dart';

class DoctorViewModel extends BaseViewModel {
  final ReportsService _reportsService = locator<ReportsService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  List<PatientReport> _reports = [];
  List<PatientReport> get reports => _reports;

  String? _selectedPatientId;
  String? get selectedPatientId => _selectedPatientId;

  List<PatientReport> get selectedReports =>
      _reports.where((r) => r.patientId == _selectedPatientId).toList();

  final Map<String, String> _patientNames = {}; // uid -> name
  String patientName(String id) => _patientNames[id] ?? id;

  final TextEditingController noteController = TextEditingController();

  Future<void> init() async {
    final String? doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return;

    setBusy(true);
    _reportsService.watchReportsForDoctor(doctorId).listen((data) async {
      _reports = data;

      // resolve patient names
      final ids = _reports.map((e) => e.patientId).toSet();
      for (var pid in ids) {
        if (!_patientNames.containsKey(pid)) {
          final user = await _reportsService.fetchUserById(pid);
          if (user != null) {
            _patientNames[pid] = user.name ?? user.email;
          }
        }
      }

      notifyListeners();
    });
    setBusy(false);
  }

  void selectPatient(String patientId) {
    _selectedPatientId = patientId;
    notifyListeners();
  }

  Future<void> addNoteToSelectedReport(String noteText) async {
    if (noteText.trim().isEmpty) return;
    if (selectedReports.isEmpty) return;

    final DoctorNote note = DoctorNote(
      doctorId: _auth.currentUser!.uid,
      note: noteText.trim(),
      createdAt: DateTime.now(),
    );

    // For simplicity add note to the most recent report
    await _reportsService.addNoteToReport(
      reportId: selectedReports.first.id,
      note: note,
    );
  }

  Future<void> addNoteToReportForPatient(String patientId) async {
    final noteText = noteController.text.trim();
    if (noteText.isEmpty) return;

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
      note: noteText,
      createdAt: DateTime.now(),
    );

    await _reportsService.addNoteToReport(reportId: report.id, note: note);
    noteController.clear();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
