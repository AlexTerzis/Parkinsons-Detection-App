import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkinsondetetion/ui/views/login/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stacked_services/stacked_services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import '../../../app/app.locator.dart';
import '../../../services/authentication_service.dart';
import '../../../services/test_service.dart';
import '../../../services/reports_service.dart';
import '../../../services/drawing_predictor.dart';
import '../../../models/test_result.dart';
import '../../../models/patient_report.dart';
import '../../../models/app_user.dart';
import '../../../models/test_type.dart';

class PatienceViewModel extends BaseViewModel {
  final AuthenticationService _authService = locator<AuthenticationService>();
  final TestService _testService = locator<TestService>();
  final ReportsService _reportsService = locator<ReportsService>();
  final DrawingPredictor _drawingPredictor = DrawingPredictor();

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

  // Number of days to average over for trend chart
  int _selectedAverageWindow = 7;
  int get selectedAverageWindow => _selectedAverageWindow;

  Map<String, double> get resultsSummary =>
      _testService.computeSummary(_results);

  Map<TestType, List<TestResult>> get groupedResults {
    final Map<TestType, List<TestResult>> map = {};
    for (var r in _results) {
      map.putIfAbsent(r.type, () => []).add(r);
    }
    return map;
  }

  double latestScoreForType(TestType type) =>
      groupedResults[type]?.first.score ?? 0.0;

  List<PatientReport> _reports = [];
  List<PatientReport> get reports => _reports;

  final Map<String, AppUser> _doctorLookup = {};
  String doctorName(String id) => _doctorLookup[id]?.name ?? id;
  AppUser? doctorById(String id) => _doctorLookup[id];

  String? _primaryDoctorId;
  String? get primaryDoctorId => _primaryDoctorId;
  AppUser? get primaryDoctor =>
      _primaryDoctorId == null ? null : _doctorLookup[_primaryDoctorId];

  List<AppUser> _doctors = [];
  List<AppUser> get doctors => _doctors;

  List<String> get secondOpinionDoctorIds {
    final ids = _reports.map((r) => r.doctorId).toSet();
    ids.remove(_primaryDoctorId);
    return ids.toList();
  }

  // Subscriptions for realtime updates
  StreamSubscription<List<TestResult>>? _resultsSub;
  StreamSubscription<List<PatientReport>>? _reportsSub;

  // Summary items for display
  List<Map<String, String>> get historyItems => _results
      .map((r) => {
            'date': '${r.performedAt.month}/${r.performedAt.day}  ${r.performedAt.hour.toString().padLeft(2, '0')}:${r.performedAt.minute.toString().padLeft(2, '0')}',
            'test': _labelForType(r),
            'result': '${(r.score * 100).round()}%',
          })
      .toList();

  /// Whether this session is an anonymous guest one.
  ///
  /// Guests can take every test and see their own results, but nothing that
  /// implies a persistent identity or a doctor relationship.
  bool get isGuest => _authService.isGuest;

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

    // Every step below is best-effort: a failure in any one of them must not
    // leave the view stuck on its loading spinner, so setBusy(false) runs in
    // a finally and the optional lookups swallow their own errors.
    try {
      _name = await _authService.fetchDisplayName() ?? '--';
      nameController.text = _name == '--' ? '' : _name;

      final String? uid = _authService.currentUser?.uid;
      if (uid != null) {
        // Subscribe to test results and keep the subscription
        _resultsSub = _testService.watchResultsForPatient(uid).listen((list) {
          _results = list;
          notifyListeners();
        });

        // Guests have no doctor relationship, so skip everything that depends
        // on one rather than doing the work and hiding the result.
        if (!isGuest) {
          _reportsSub =
              _reportsService.watchReportsForPatient(uid).listen((data) {
            _reports = data;
            notifyListeners();
          });
        }

        // Fetch extra profile data (DOB + medication) from Firestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          final data = doc.data();
          if (data != null) {
            _dob = data['dob'] ?? '';
            _medication = data['medication'] ?? '';
            _primaryDoctorId = data['primaryDoctorId'] as String?;
            dobController.text = _dob;
            medicationController.text = _medication;
          }
        } catch (e) {
          debugPrint('Could not load profile fields: $e');
        }

        // Preload doctor lookup map. This is a collection query over `users`,
        // which the security rules deny for non-doctor accounts; without this
        // guard the throw skipped setBusy(false) and the home screen hung on
        // its spinner forever, which looked like a failed login.
        if (!isGuest) {
          try {
            _doctors = await _reportsService.fetchAllDoctors();
            for (var d in _doctors) {
              _doctorLookup[d.uid] = d;
            }
          } catch (e) {
            debugPrint('Could not preload doctors: $e');
            _doctors = [];
          }
        }
      }
    } catch (e) {
      debugPrint('PatienceViewModel.init failed: $e');
    } finally {
      setBusy(false);
    }
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

    // set(merge) rather than update(): update() throws when the profile
    // document does not exist yet, which is reachable for any account whose
    // document was never created.
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'dob': _dob,
        'medication': _medication,
      },
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    // Cancel subscriptions to avoid memory leaks
    _resultsSub?.cancel();
    _reportsSub?.cancel();
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

  Future<void> sendResultsToPrimaryDoctor() async {
    final id = _primaryDoctorId;
    if (id == null) return;
    await sendResultsToDoctor(id);
  }

  Future<void> setPrimaryDoctor(String doctorId) async {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null) return;
    _primaryDoctorId = doctorId;
    notifyListeners();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'primaryDoctorId': doctorId}, SetOptions(merge: true));
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

    await _testService.addResult(result: res);
  }

  /// Update the number of days used for the moving average
  void updateAverageWindow(int days) {
    // Ignore if the same value is selected
    if (_selectedAverageWindow == days) return;
    _selectedAverageWindow = days;
    notifyListeners();
  }

  /// Calculate the N-day moving average trend for all test scores
  List<FlSpot> getAverageTrend() {
    // Nothing to plot if there are no results
    if (_results.isEmpty) return [];

    // 1. Bucket every result by its calendar day
    final Map<DateTime, List<TestResult>> daily = {};
    for (final r in _results) {
      final d = DateTime(r.performedAt.year, r.performedAt.month, r.performedAt.day);
      daily.putIfAbsent(d, () => []).add(r);
    }

    // 2. Compute the average score for each day
    final dailyAvg = daily.entries.map((e) {
      final scores = e.value.map((r) => r.score).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(e.key, avg);
    }).toList();

    // 3. Sort days chronologically for cumulative processing
    dailyAvg.sort((a, b) => a.key.compareTo(b.key));

    // 4. Walk through the list computing moving averages
    final List<FlSpot> spots = [];
    final values = dailyAvg.map((e) => e.value).toList();
    for (int i = 0; i < values.length; i++) {
      final start = math.max(0, i - _selectedAverageWindow + 1);
      final slice = values.sublist(start, i + 1);
      final avg = slice.reduce((a, b) => a + b) / slice.length;
      spots.add(FlSpot(i.toDouble(), avg));
    }

    return spots;
  }

  // Type to label mapping
  String _labelForType(TestResult r) {
    return labelForType(r.type);
  }

  String labelForType(TestType type) {
    switch (type) {
      case TestType.drawing:
        return 'Drawing';
      case TestType.questionnaire:
        return 'Questionnaire';
      case TestType.tremor:
        return 'Tremor';
      case TestType.tap:
        return 'Tap';
      case TestType.voice:
        return 'Voice';
      case TestType.cameraDetection:
        return 'Camera Detection';
      case TestType.neuro:
        return 'Neuropsychological';
      case TestType.fab:
        return 'FAB';
    }
  }

  /// Generic handler that decides how to process [source] and stores the
  /// resulting score. The [source] can be a [ui.Image] from the drawing
  /// canvas or a [File] from the gallery/camera.
  Future<DrawingPrediction> handleDrawingPrediction(dynamic source) async {
    DrawingPrediction prediction;
    if (source is ui.Image) {
      prediction = await _drawingPredictor.predictCanvas(source);
    } else if (source is File) {
      prediction = await _drawingPredictor.predictFile(source);
    } else {
      throw ArgumentError('Unsupported image source: $source');
    }

    // Persist the confidence score so it appears in history.
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final pngBytes = source is ui.Image
          ? (await source
                  .toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List()
          : await (source as File).readAsBytes();
      final result = TestResult(
        id: '',
        patientId: uid,
        type: TestType.drawing,
        performedAt: DateTime.now(),
        score: prediction.confidence.clamp(0, 1),
        data: {'label': prediction.label},
      );
      await _testService.addResult(
        result: result,
        drawingPng: pngBytes,
      );
      if (source is File) {
        try {
          await source.delete();
        } catch (_) {}
      }
    }

     final ctx = locator<NavigationService>().navigatorKey!.currentContext;
     if (ctx != null) {
      String message;
      if (prediction.label == 'Parkinson') {
        message =
            '🧠 Parkinson with probability ${(prediction.confidence * 100).toStringAsFixed(1)}%';
      } else {
        final healthyProb =
            ((1 - prediction.confidence) * 100).clamp(0, 100).toStringAsFixed(1);
        message = '💪 Healthy with probability $healthyProb%';
      }

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return prediction;
  }

  Future<void> handleCanvasDrawing(ui.Image img) async {
    await handleDrawingPrediction(img);
  }

  Future<void> handleCameraImage(File file) async {
    await handleDrawingPrediction(file);
  }

  Future<void> handleGalleryImage(File file) async {
    await handleDrawingPrediction(file);
  }
}
