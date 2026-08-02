import 'package:firebase_auth/firebase_auth.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_view.dart';
import '../../../app/app.locator.dart';
import '../../../services/reports_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/patient_report.dart';
import '../../../models/doctor_note.dart';

class DoctorViewModel extends BaseViewModel {
  final ReportsService _reportsService = locator<ReportsService>();
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

  String? _selectedPatientId;
  String? get selectedPatientId => _selectedPatientId;

  List<PatientReport> get selectedReports =>
      _reports.where((r) => r.patientId == _selectedPatientId).toList();

  final Map<String, String> _patientNames = {}; // uid -> name
  String patientName(String id) => _patientNames[id] ?? id;

  final TextEditingController noteController = TextEditingController();

  /// Sample community posts; in the future these would come from Firestore.
  List<Map<String, String>> posts = [];

  Future<void> init() async {
    final String? doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return;

    setBusy(true);

    // Load profile info
    _name = await _auth.fetchDisplayName() ?? '--';
    nameController.text = _name == '--' ? '' : _name;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
    final data = doc.data();
    if (data != null) {
      _specialty = data['specialty'] ?? '';
      _location = data['location'] ?? '';
      specialtyController.text = _specialty;
      locationController.text = _location;
    }

    // Demo community posts
    posts = [
      {
        'author': _name,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'content': 'Excited to join the community!'
      }
    ];

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
    final pid = _selectedPatientId;
    if (pid == null) return;
    await addNoteToReportForPatient(pid, noteText: noteText);
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


