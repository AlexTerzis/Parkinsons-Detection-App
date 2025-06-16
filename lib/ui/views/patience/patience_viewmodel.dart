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

  String _name = '--';
  String get name => _name.isEmpty ? '--' : _name;

  // Controller for editing name
  final TextEditingController nameController = TextEditingController();

  // Reactive data
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

  List<Map<String, String>> get historyItems => _results
      .map((r) => {
            'date': '${r.performedAt.month}/${r.performedAt.day}  ${r.performedAt.hour.toString().padLeft(2,'0')}:${r.performedAt.minute.toString().padLeft(2,'0')}',
            'test': _labelForType(r),
            'result': '${(r.score * 100).round()}%',
          })
      .toList();

  Future<void> init() async {
    setBusy(true);
    _name = await _authService.fetchDisplayName() ?? '--';
    nameController.text = _name == '--' ? '' : _name;

    final String? uid = _authService.currentUser?.uid;
    if (uid != null) {
      _testService.watchResultsForPatient(uid).listen((list) {
        _results = list;
        notifyListeners();
      });

      _reportsService.watchReportsForPatient(uid).listen((data) {
        _reports = data;
        notifyListeners();
      });

      // Preload doctors for lookup
      _doctors = await _reportsService.fetchAllDoctors();
      for (var d in _doctors) {
        _doctorLookup[d.uid] = d;
      }
    }
    setBusy(false);
  }

  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;

    _name = newName.trim();
    notifyListeners();
    await _authService.updateDisplayName(_name);
  }

  Future<void> saveName() async {
    await updateName(nameController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

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

  String _labelForType(TestResult r) {
    switch (r.type) {
      case TestType.drawing:
        return 'Drawing';
      case TestType.questionnaire:
        return 'Questionnaire';
      case TestType.cameraDetection:
      default:
        return 'Camera Detection';
    }
  }
}
