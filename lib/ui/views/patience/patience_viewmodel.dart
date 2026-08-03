import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkinsondetetion/ui/views/login/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked_services/stacked_services.dart';
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
import '../drawing_test/drawing_result_view.dart';
import '../drawing_test/signature_canvas_view.dart';

class PatienceViewModel extends BaseViewModel {
  final AuthenticationService _authService = locator<AuthenticationService>();
  final TestService _testService = locator<TestService>();
  final ReportsService _reportsService = locator<ReportsService>();
  final DrawingPredictor _drawingPredictor = DrawingPredictor();

  String get email => _authService.currentUser?.email ?? '--';

  // --- Profile fields ---
  String _name = '--';
  String get name => _name.isEmpty ? '--' : _name;

  // Controllers for editing profile fields
  final TextEditingController nameController = TextEditingController();

  // --- Reactive data ---
  List<TestResult> _results = [];
  List<TestResult> get results => _results;

  // Number of days to average over for trend chart
  int _selectedAverageWindow = 7;
  int get selectedAverageWindow => _selectedAverageWindow;

  /// Test types kept out of the charts.
  ///
  /// The questionnaire is self-reported history, not a measurement: it barely
  /// changes between sittings, so as a trend line it is a flat bar that drags
  /// the overall average around, and on the radar it sits next to five measured
  /// tests as though it were one of them. It is still stored and still sent to
  /// the doctor — it is only excluded from the score charts.
  static const Set<TestType> _excludedFromCharts = {TestType.questionnaire};

  /// Results that the score charts are built from.
  List<TestResult> get scoredResults =>
      _results.where((r) => !_excludedFromCharts.contains(r.type)).toList();

  /// Average concern per test, across every attempt of it.
  ///
  /// Keyed by [TestType] rather than by a name: the name is language-dependent
  /// and belongs to the widget that draws it, which is what `computeSummary`
  /// got wrong — its hardcoded English keys were drawn straight onto the radar,
  /// so the Greek app labelled its spokes "Drawing" and "Tremor".
  Map<TestType, double> get averageConcernByType {
    return groupedResults.map((type, list) {
      final avg = list.map((r) => r.concernScore).reduce((a, b) => a + b) /
          list.length;
      return MapEntry(type, avg);
    });
  }

  Map<TestType, List<TestResult>> get groupedResults {
    final Map<TestType, List<TestResult>> map = {};
    for (var r in scoredResults) {
      map.putIfAbsent(r.type, () => []).add(r);
    }
    return map;
  }

  double latestScoreForType(TestType type) =>
      groupedResults[type]?.first.concernScore ?? 0.0;

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

  /// Whether this session is an anonymous guest one.
  ///
  /// Guests can take every test and see their own results, but nothing that
  /// implies a persistent identity or a doctor relationship.
  bool get isGuest => _authService.isGuest;

  // Logout and clear preference
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('keepMeLoggedIn');
    // Cleared with the session, so the next account to sign in on this device
    // cannot be routed by the previous one's role on a slow launch.
    await prefs.remove('cachedRole');
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

        // Fetch the profile document for the chosen doctor.
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          final data = doc.data();
          if (data != null) {
            _primaryDoctorId = data['primaryDoctorId'] as String?;
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

  @override
  void dispose() {
    // Cancel subscriptions to avoid memory leaks
    _resultsSub?.cancel();
    _reportsSub?.cancel();
    nameController.dispose();
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

  /// One point per day on which tests were taken inside the selected window,
  /// oldest first, each the average concern across that day's tests.
  ///
  /// The window is counted in real calendar days back from today, which is what
  /// "last 7 days" plainly means. It used to be a moving average over the last
  /// N *entries*, so picking 30 on an account with eight results changed
  /// nothing, and the smoothing quietly flattened exactly the change the chart
  /// existed to show.
  List<MapEntry<DateTime, double>> dailyAverages() {
    final scored = scoredResults;
    if (scored.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Inclusive of today, so a 7-day window spans today and the six days
    // before it rather than eight days in total.
    final cutoff = today.subtract(Duration(days: _selectedAverageWindow - 1));

    final Map<DateTime, List<double>> byDay = {};
    for (final r in scored) {
      final d = DateTime(
        r.performedAt.year,
        r.performedAt.month,
        r.performedAt.day,
      );
      if (d.isBefore(cutoff)) continue;
      byDay.putIfAbsent(d, () => []).add(r.concernScore);
    }

    final points = byDay.entries
        .map((e) => MapEntry(
              e.key,
              e.value.reduce((a, b) => a + b) / e.value.length,
            ))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return points;
  }

  // Test names are localized, so they are built in the widget layer from
  // AppLocalizations — see `testTypeLabel`. A view model has no context and
  // cannot produce them correctly.

  /// Generic handler that decides how to process [source] and stores the
  /// resulting score. The [source] can be a [ui.Image] from the drawing
  /// canvas or a [File] from the gallery/camera.
  Future<DrawingPrediction> handleDrawingPrediction(
    dynamic source, {
    required String drawingType,
    required String inputMethod,
    bool replaceCurrent = false,
  }) async {
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
    final pngBytes = source is ui.Image
        ? (await source.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List()
        : await (source as File).readAsBytes();
    var saved = uid != null;
    if (uid != null) {
      final result = TestResult(
        id: '',
        patientId: uid,
        type: TestType.drawing,
        performedAt: DateTime.now(),
        score: prediction.confidence.clamp(0, 1).toDouble(),
        data: {
          'label': prediction.label,
          'drawingType': drawingType,
          'inputMethod': inputMethod,
          'protocol': 'freehand',
        },
      );
      try {
        await _testService.addResult(result: result, drawingPng: pngBytes);
      } catch (error) {
        saved = false;
        debugPrint('Could not save drawing result: $error');
      }
      if (source is File) {
        try {
          await source.delete();
        } catch (_) {}
      }
    }

    final navigator = locator<NavigationService>().navigatorKey?.currentState;
    if (navigator != null) {
      final route = MaterialPageRoute<bool>(
        builder: (_) => DrawingResultView(
          pngBytes: pngBytes,
          drawingType: drawingType,
          inputMethod: inputMethod,
          label: prediction.label,
          parkinsonProbability: prediction.confidence,
          saved: saved,
        ),
      );
      final retry = replaceCurrent
          ? await navigator.pushReplacement<bool, void>(route)
          : await navigator.push<bool>(route);
      if (retry == true) {
        if (inputMethod == 'canvas') {
          _openDrawingCanvas(drawingType);
        } else if (inputMethod == 'camera') {
          pickDrawingFromCamera(drawingType);
        } else {
          pickDrawingFromGallery(drawingType);
        }
      }
    }

    return prediction;
  }

  Future<void> handleCanvasDrawing(
    ui.Image img, {
    String drawingType = 'spiral',
    String inputMethod = 'canvas',
    bool replaceCurrent = false,
  }) async {
    await handleDrawingPrediction(img,
        drawingType: drawingType,
        inputMethod: inputMethod,
        replaceCurrent: replaceCurrent);
  }

  Future<void> handleCameraImage(File file,
      {String drawingType = 'spiral'}) async {
    await handleDrawingPrediction(file,
        drawingType: drawingType, inputMethod: 'camera');
  }

  Future<void> handleGalleryImage(File file,
      {String drawingType = 'spiral'}) async {
    await handleDrawingPrediction(file,
        drawingType: drawingType, inputMethod: 'gallery');
  }

  void _openDrawingCanvas(String drawingType) {
    final navigator = locator<NavigationService>().navigatorKey?.currentState;
    navigator?.push(MaterialPageRoute<void>(
      builder: (_) => SignatureCanvasView(
        drawingType: drawingType,
        onImageReady: (_) {},
        onAnalyze: (image) => handleCanvasDrawing(image,
            drawingType: drawingType,
            inputMethod: 'canvas',
            replaceCurrent: true),
      ),
    ));
  }

  Future<void> pickDrawingFromCamera(String drawingType) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      await handleCameraImage(File(picked.path), drawingType: drawingType);
    }
  }

  Future<void> pickDrawingFromGallery(String drawingType) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await handleGalleryImage(File(picked.path), drawingType: drawingType);
    }
  }
}
