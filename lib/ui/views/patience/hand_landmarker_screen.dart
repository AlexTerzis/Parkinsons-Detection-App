// --- Data Structures ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkinsondetetion/app/app.locator.dart' show locator;
import 'package:parkinsondetetion/models/landmark_point.dart';
import 'package:parkinsondetetion/services/hand_metrics.dart';
import 'package:parkinsondetetion/services/parkinson_config.dart';
import 'package:permission_handler/permission_handler.dart';
class LandmarkData {
  final String handedness; // 'Left', 'Right', or 'Unknown'
  final List<LandmarkPoint> landmarks;

  LandmarkData({required this.handedness, required this.landmarks});
}

class FrameData {
  final int timestamp;
  final List<LandmarkData> hands;

  FrameData({required this.timestamp, required this.hands});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkinson\'s Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HandLandmarkerScreen(),
    );
  }
}

class HandLandmarkerScreen extends StatefulWidget {
  final void Function(FrameData)? onFrame;

  const HandLandmarkerScreen({super.key, this.onFrame});

  @override
  State<HandLandmarkerScreen> createState() => _HandLandmarkerScreenState();
}

class _HandLandmarkerScreenState extends State<HandLandmarkerScreen> {
  List<dynamic> _landmarks = [];
  bool _hasPermission = false;

  // --- Parkinson's Detection State ---
  final List<FrameData> _landmarkHistory = [];
  static const int _historyLength = 30; // frames kept for analysis
  static const int _tremorWindowSize = 10; // window size for tremor metric
  static const double _symptomThreshold = ParkinsonConfig.symptomThreshold; // threshold for demo alerts

  double _speedVarianceLeft = 0.0, _speedVarianceRight = 0.0;
  double _tremorScoreLeft = 0.0, _tremorScoreRight = 0.0;
  double _accelVarianceLeft = 0.0, _accelVarianceRight = 0.0;
  double _jerkVarianceLeft = 0.0, _jerkVarianceRight = 0.0;
  double _spreadLeft = 0.0, _spreadRight = 0.0;
  double _asymmetryScore = 0.0; // Overall asymmetry score
  bool _potentialSymptomsDetected = false;
  final HandMetrics _metrics = locator<HandMetrics>();

  // Landmark indices (refer to MediaPipe documentation)
  final int _thumbTipIndex = 4;
  final int _wristIndex = 0; //TODO mallon remove

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status == PermissionStatus.granted;
      });
    }
  }

  // --- Landmark Processing Callback ---
  void _onLandmarksDetected(List<dynamic> detectedHandsData) {
    if (!mounted) return;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final List<LandmarkData> currentHands = [];

    // Parse data from native code
    final parsed = _metrics.parseRawHands(detectedHandsData);
    parsed.forEach((side, points) {
      if (points.length > _thumbTipIndex) {
        currentHands.add(LandmarkData(handedness: side, landmarks: points));
      } else {
        print("Warning: Landmark data format unexpected or missing thumb tip.");
      }
    });

    setState(() {
      // Keep raw data for text display if needed
      _landmarks = detectedHandsData;

      // Update history and calculate metrics
      if (currentHands.isNotEmpty) {
        _landmarkHistory
            .add(FrameData(timestamp: timestamp, hands: currentHands));
        if (_landmarkHistory.length > _historyLength) {
          _landmarkHistory.removeAt(0);
        }
        _updateSymptomMetrics();
        widget.onFrame?.call(FrameData(timestamp: timestamp, hands: currentHands));
      } else {
      
      }
    });
  }

  // --- Symptom Metric Calculation ---
  void _updateSymptomMetrics() {
    if (_landmarkHistory.length < _tremorWindowSize)
      return; // Need minimum data

    List<List<LandmarkPoint>?> leftHistory = _getHandHistory('Left');
    List<List<LandmarkPoint>?> rightHistory = _getHandHistory('Right');

    // Check if hands were actually present recently enough for calculation
    bool leftHandPresent = leftHistory.any((h) => h != null);
    bool rightHandPresent = rightHistory.any((h) => h != null);

    final allLeftTrajectories =
        List.generate(21, (i) => _metrics.extractTrajectory(leftHistory, i));
    final allRightTrajectories =
        List.generate(21, (i) => _metrics.extractTrajectory(rightHistory, i));

    _speedVarianceLeft =
        leftHandPresent ? _metrics.speedVarianceAll(allLeftTrajectories) : 0.0;
    _speedVarianceRight =
        rightHandPresent ? _metrics.speedVarianceAll(allRightTrajectories) : 0.0;
    _accelVarianceLeft =
        leftHandPresent ? _metrics.accelerationVarianceAll(allLeftTrajectories) : 0.0;
    _accelVarianceRight =
        rightHandPresent ? _metrics.accelerationVarianceAll(allRightTrajectories) : 0.0;
    _jerkVarianceLeft =
        leftHandPresent ? _metrics.jerkVarianceAll(allLeftTrajectories) : 0.0;
    _jerkVarianceRight =
        rightHandPresent ? _metrics.jerkVarianceAll(allRightTrajectories) : 0.0;
    _spreadLeft = leftHandPresent ? _metrics.fingerSpread(allLeftTrajectories) : 0.0;
    _spreadRight = rightHandPresent ? _metrics.fingerSpread(allRightTrajectories) : 0.0;

    final trimmedLeft =
        allLeftTrajectories.map((t) => t.length > _tremorWindowSize
            ? t.sublist(t.length - _tremorWindowSize)
            : t).toList();
    final trimmedRight =
        allRightTrajectories.map((t) => t.length > _tremorWindowSize
            ? t.sublist(t.length - _tremorWindowSize)
            : t).toList();

    _tremorScoreLeft =
        leftHandPresent ? _metrics.tremorAll(trimmedLeft) : 0.0;
    _tremorScoreRight =
        rightHandPresent ? _metrics.tremorAll(trimmedRight) : 0.0;

    // Simple asymmetry across all metrics (normalized 0-1)
    if (leftHandPresent && rightHandPresent) {
      final diffs = [
        (_speedVarianceLeft - _speedVarianceRight).abs(),
        (_tremorScoreLeft - _tremorScoreRight).abs(),
        (_accelVarianceLeft - _accelVarianceRight).abs(),
        (_jerkVarianceLeft - _jerkVarianceRight).abs(),
        (_spreadLeft - _spreadRight).abs(),
      ];
      final meanDiff = diffs.reduce((a, b) => a + b) / diffs.length;
      _asymmetryScore = meanDiff.clamp(0.0, 1.0);
    } else {
      _asymmetryScore = 0.0; // No asymmetry if only one hand is present
    }

    // Simple Indication Logic
    int highMetricsCount = 0;
    if (_speedVarianceLeft > _symptomThreshold && leftHandPresent)
      highMetricsCount++;
    if (_speedVarianceRight > _symptomThreshold && rightHandPresent)
      highMetricsCount++;
    if (_tremorScoreLeft > _symptomThreshold && leftHandPresent)
      highMetricsCount++;
    if (_tremorScoreRight > _symptomThreshold && rightHandPresent)
      highMetricsCount++;
    if (_accelVarianceLeft > _symptomThreshold && leftHandPresent)
      highMetricsCount++;
    if (_accelVarianceRight > _symptomThreshold && rightHandPresent)
      highMetricsCount++;
    if (_jerkVarianceLeft > _symptomThreshold && leftHandPresent)
      highMetricsCount++;
    if (_jerkVarianceRight > _symptomThreshold && rightHandPresent)
      highMetricsCount++;
    if (_asymmetryScore > _symptomThreshold &&
        leftHandPresent &&
        rightHandPresent) {
      highMetricsCount++;
    }

    _potentialSymptomsDetected =
        highMetricsCount >= 2; // Example: 2 or more metrics are high
  }

  // Helper to extract history for a specific hand
  List<List<LandmarkPoint>?> _getHandHistory(String handedness) {
    List<List<LandmarkPoint>?> history = [];
    for (var frame in _landmarkHistory) {
      LandmarkData handData = frame.hands.firstWhere(
          (h) => h.handedness == handedness,
          orElse: () => LandmarkData(
              handedness: 'None', landmarks: []) // Placeholder if not found
          );
      if (handData.handedness == handedness && handData.landmarks.isNotEmpty) {
        history.add(handData.landmarks);
      } else {
        history.add(
            null); // Add null to indicate the hand wasn't present in this frame
      }
    }
    return history;
  }

  // --- Calculation Helpers ---
  // Detailed metric implementations reside in [HandMetrics].

  // --- UI Building ---

  // Builds the symptom bars widget
  Widget _buildSymptomBars() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Symptom Indicators (Demo)",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 8),
          _buildBar("Speed Var (L)", _speedVarianceLeft),
          _buildBar("Speed Var (R)", _speedVarianceRight),
          _buildBar("Tremor (L)", _tremorScoreLeft),
          _buildBar("Tremor (R)", _tremorScoreRight),
          _buildBar("Accel Var (L)", _accelVarianceLeft),
          _buildBar("Accel Var (R)", _accelVarianceRight),
          _buildBar("Jerk Var (L)", _jerkVarianceLeft),
          _buildBar("Jerk Var (R)", _jerkVarianceRight),
          _buildBar("Spread (L)", _spreadLeft),
          _buildBar("Spread (R)", _spreadRight),
          _buildBar("Asymmetry", _asymmetryScore),
          const SizedBox(height: 8),
          Center(
            // Center the chip
            child: Chip(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              label: Text(
                  _potentialSymptomsDetected
                      ? "Potential Symptoms Detected"
                      : "No Significant Symptoms Detected",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: _potentialSymptomsDetected
                  ? Colors.orangeAccent
                  : Colors.green[300],
              labelStyle: const TextStyle(
                  color: Colors.black87), // Ensure text is visible
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              "",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a single indicator bar row
  Widget _buildBar(String label, double value) {
    Color barColor = Colors.green;
    if (value > 0.7)
      barColor = Colors.red;
    else if (value > 0.4) barColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Adjusted padding
      child: Row(
        // mainAxisSize: MainAxisSize.min, // Removed for Expanded to work
        children: [
          SizedBox(
            width: 95, // Adjusted width
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 5), // Reduced space
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8, // Slightly thicker bar
            ),
          ),
          const SizedBox(width: 5), // Reduced space
          SizedBox(
            // Fixed width for value text
            width: 30,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to format landmark text (adapted for new structure)
  String _generateSummaryText(List<dynamic> landmarks) {
    if (landmarks.isEmpty) {
      return 'No hands detected.';
    }
    int handCount = 0;
    int pointsPerHand = 0;
    try {
      // Assumes _landmarks is List<Map<String, dynamic>> as sent by native now
      handCount = landmarks.length;
      if (handCount > 0 && landmarks[0] is Map) {
        final handData = landmarks[0] as Map;
        if (handData.containsKey('landmarks') &&
            handData['landmarks'] is List) {
          final landmarkList = handData['landmarks'] as List;
          if (landmarkList.isNotEmpty) {
            pointsPerHand = landmarkList.length;
          }
        }
      }
    } catch (e) {
      print("Error parsing summary data: $e");
      // Fallback or default values?
      handCount = landmarks.length; // Best guess
      pointsPerHand = 0;
    }
    return 'Detected $handCount hand(s), $pointsPerHand points/hand.'; // Simplified text
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Parkinson\'s Detection'),
      ),
      body: _hasPermission
          ? Stack(
              // Use Stack for overlaying
              children: [
                // Camera View + Native Overlay
                HandLandmarkerView(
                  onLandmarksDetected:
                      _onLandmarksDetected, // Use the updated callback
                ),

                // Symptom Indicator Overlay (Top Right)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ConstrainedBox(
                      // Constrain width of symptom box
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width *
                            0.6, // Max 60% of screen width
                      ),
                      child: _buildSymptomBars(),
                    ),
                  ),
                ),

                // Original Text data overlay positioned at the bottom (Optional)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height / 4,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _generateSummaryText(_landmarks), // Updated summary
                            style: const TextStyle(
                                fontSize: 14, // Adjusted size
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              // Permission not granted view
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Camera permission needed to run this demo."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _checkCameraPermission,
                    child: const Text("Grant Permission"),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _landmarkHistory.clear(); // Clear history on dispose
    super.dispose();
  }
}

// --- HandLandmarkerView Widget ---
// (This remains largely the same as before, just ensure the MethodChannel name matches)
class HandLandmarkerView extends StatefulWidget {
  final Function(List<dynamic>) onLandmarksDetected;

  const HandLandmarkerView({super.key, required this.onLandmarksDetected});

  @override
  State<HandLandmarkerView> createState() => _HandLandmarkerViewState();
}

class _HandLandmarkerViewState extends State<HandLandmarkerView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    // Use a unique identifier for the viewType if multiple instances are possible
    const String viewType = 'hand_landmarker_view';

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      // Pass creation parameters if needed by the native factory
      // creationParams: creationParams,
      // creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onViewCreated,
    );
  }

  void _onViewCreated(int id) {
    // Ensure the channel name matches the one used in HandLandmarkerView.kt
    _channel = MethodChannel('hand_landmarker_channel_$id');
    print("MethodChannel 'hand_landmarker_channel_$id' created."); // Debug log
    _channel!.setMethodCallHandler((call) async {
      // print("Method call received on Flutter side!!!!!!!: ${call.method}"); // Debug log
      if (call.method == 'onLandmarks') {
        try {
          // Directly pass the argument, expecting List<dynamic> (List<Map<String, dynamic>>)
          final landmarksData = call.arguments;
          if (landmarksData is List<dynamic>) {
            widget.onLandmarksDetected(landmarksData);
          } else {
            print(
                "Error: Received landmark data is not a List: ${landmarksData.runtimeType}");
            widget.onLandmarksDetected([]); // Pass empty list on format error
          }
        } catch (e, stacktrace) {
          print("Error processing landmarks in Flutter MethodCallHandler: $e");
          print(stacktrace);
          widget.onLandmarksDetected([]); // Pass empty list on error
        }
      } else {
        print("Unknown method call: ${call.method}");
      }
    });
  }

  @override
  void dispose() {
    // Clean up the channel
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
