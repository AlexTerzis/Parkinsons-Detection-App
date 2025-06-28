import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkinsondetetion/ui/views/login/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';

import '../../../app/app.locator.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../../../services/reports_service.dart';
import '../../../models/test_result.dart';
import '../../../models/patient_report.dart';
import '../../../models/app_user.dart';
import '../../../models/test_type.dart';

class PatienceViewModel extends BaseViewModel {
  final AuthenticationService _authService = locator<AuthenticationService>();
  final TestService _testService = locator<TestService>();
  final ReportsService _reportsService = locator<ReportsService>();

  String get email => _authService.currentUser?.email ?? '--';

  // --- Profile fields ---
  String _name = '--';
  String get name => _name.isEmpty ? '--' : _name;

  String _dob = ''; // Date of birth
  String get dob => _dob;

  String _medication = ''; // Medication info
  String get medication => _medication;

  // Controllers for editing profile fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController medicationController = TextEditingController();

  // --- Reactive data ---
  List<TestResult> _results = [];
  List<TestResult> get results => _results;

  Map<String, double> get resultsSummary =>
      _testService.computeSummary(_results);

  List<PatientReport> _reports = [];
  List<PatientReport> get reports => _reports;

  final Map<String, AppUser> _doctorLookup = {};
  String doctorName(String id) => _doctorLookup[id]?.name ?? id;

  List<AppUser> _doctors = [];
  List<AppUser> get doctors => _doctors;

  // Summary items for display
  List<Map<String, String>> get historyItems => _results
      .map((r) => {
            'date': '${r.performedAt.month}/${r.performedAt.day}  ${r.performedAt.hour.toString().padLeft(2, '0')}:${r.performedAt.minute.toString().padLeft(2, '0')}',
            'test': _labelForType(r),
            'result': '${(r.score * 100).round()}%',
          })
      .toList();

  // Logout and clear preference
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('keepMeLoggedIn');
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginView()),
      (route) => false,
    );
  }

  // Initialization: Load user info, subscribe to result/report streams, preload doctors
  Future<void> init() async {
    setBusy(true);

    _name = await _authService.fetchDisplayName() ?? '--';
    nameController.text = _name == '--' ? '' : _name;

    final String? uid = _authService.currentUser?.uid;
    if (uid != null) {
      // Subscribe to test results
      _testService.watchResultsForPatient(uid).listen((list) {
        _results = list;
        notifyListeners();
      });

      // Subscribe to reports
      _reportsService.watchReportsForPatient(uid).listen((data) {
        _reports = data;
        notifyListeners();
      });

      // Fetch extra profile data (DOB + medication) from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data();
      if (data != null) {
        _dob = data['dob'] ?? '';
        _medication = data['medication'] ?? '';
        dobController.text = _dob;
        medicationController.text = _medication;
      }

      // Preload doctor lookup map
      _doctors = await _reportsService.fetchAllDoctors();
      for (var d in _doctors) {
        _doctorLookup[d.uid] = d;
      }
    }

    setBusy(false);
  }

  // Save name to Firebase
  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    _name = newName.trim();
    notifyListeners();
    await _authService.updateDisplayName(_name);
  }

  Future<void> saveName() async {
    await updateName(nameController.text);
  }

  // Save extra profile fields (DOB and medication) to Firestore
  Future<void> saveExtraProfileFields() async {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _dob = dobController.text.trim();
    _medication = medicationController.text.trim();
    notifyListeners();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'dob': _dob,
      'medication': _medication,
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    medicationController.dispose();
    super.dispose();
  }

  // Send results to selected doctor
  Future<void> sendResultsToDoctor(String doctorId) async {
    if (_results.isEmpty) return;
    final String? uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setBusy(true);
    await _reportsService.sendResultsToDoctor(
      patientId: uid,
      doctorId: doctorId,
      results: _results,
    );
    setBusy(false);
  }

  // Demo generator
  Future<void> recordDemoResult(TestType type) async {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null) return;

    final TestResult res = TestResult(
      id: '',
      patientId: uid,
      type: type,
      performedAt: DateTime.now(),
      score: (DateTime.now().millisecondsSinceEpoch % 100) / 100.0,
    );

    await _testService.addResult(res);
  }

  // Type to label mapping
  String _labelForType(TestResult r) {
    switch (r.type) {
      case TestType.drawing:
        return 'Drawing';
      case TestType.questionnaire:
        return 'Questionnaire';
      case TestType.tremor:
        return 'Tremor';
      case TestType.tap:
        return 'Tap';
      case TestType.cameraDetection:
      default:
        return 'Camera Detection';
    }
  }
}
