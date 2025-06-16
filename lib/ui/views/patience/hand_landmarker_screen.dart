// --- Data Structures ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

class LandmarkData {
  final String handedness; // 'Left', 'Right', or 'Unknown'
  final List<Map<String, double>> landmarks;

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
  final int _historyLength = 30; // Number of frames for analysis
  final int _tremorWindowSize = 10; // Frames for tremor calculation
  final double _symptomThreshold = 0.6; // Example threshold for indication

  double _speedVarianceLeft = 0.0, _speedVarianceRight = 0.0;
  double _tremorScoreLeft = 0.0, _tremorScoreRight = 0.0;
  double _asymmetryScore = 0.0; // Overall asymmetry score
  bool _potentialSymptomsDetected = false;

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
    for (var handDataRaw in detectedHandsData) {
      if (handDataRaw is Map) {
        final Map<String, dynamic> handData =
            Map<String, dynamic>.from(handDataRaw);
        final String handedness =
            handData['handedness'] as String? ?? 'Unknown';
        final List<dynamic>? landmarksRaw = handData['landmarks'] as List?;

        if (landmarksRaw != null) {
          // Basic validation: Ensure it's a List and contains Maps
          if (landmarksRaw is List &&
              landmarksRaw.isNotEmpty &&
              landmarksRaw.first is Map) {
            try {
              final List<Map<String, double>> landmarks = landmarksRaw
                  .map((lm) => Map<String, double>.from(lm as Map))
                  .toList();
              // Check if expected landmarks exist (e.g., thumb tip)
              if (landmarks.length > _thumbTipIndex &&
                  landmarks[_thumbTipIndex].containsKey('x')) {
                currentHands.add(
                    LandmarkData(handedness: handedness, landmarks: landmarks));
              } else {
                print(
                    "Warning: Landmark data format unexpected or missing thumb tip.");
              }
            } catch (e) {
              print("Error casting landmark data: $e");
            }
          } else if (landmarksRaw.isNotEmpty) {
            print(
                "Warning: Landmark list item format unexpected: ${landmarksRaw.first.runtimeType}");
          }
        }
      } else {
        print(
            "Warning: Hand data format unexpected: ${handDataRaw.runtimeType}");
      }
    }

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

    List<List<Map<String, double>>?> leftHistory = _getHandHistory('Left');
    List<List<Map<String, double>>?> rightHistory = _getHandHistory('Right');

    // Check if hands were actually present recently enough for calculation
    bool leftHandPresent = leftHistory.any((h) => h != null);
    bool rightHandPresent = rightHistory.any((h) => h != null);

    _speedVarianceLeft = leftHandPresent
        ? _calculateSpeedVariance(leftHistory, _thumbTipIndex)
        : 0.0;
    _speedVarianceRight = rightHandPresent
        ? _calculateSpeedVariance(rightHistory, _thumbTipIndex)
        : 0.0;

    _tremorScoreLeft = leftHandPresent
        ? _calculateTremorScore(leftHistory, _thumbTipIndex, _tremorWindowSize)
        : 0.0;
    _tremorScoreRight = rightHandPresent
        ? _calculateTremorScore(rightHistory, _thumbTipIndex, _tremorWindowSize)
        : 0.0;

    // Simple asymmetry: average difference normalized (0-1)
    if (leftHandPresent && rightHandPresent) {
      double diffSpeed = (_speedVarianceLeft - _speedVarianceRight).abs();
      double diffTremor = (_tremorScoreLeft - _tremorScoreRight).abs();
      // Normalize roughly, assuming max difference could be around 1.0 for each metric's scale
      _asymmetryScore = ((diffSpeed + diffTremor) / 2.0).clamp(0.0, 1.0);
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
    if (_asymmetryScore > _symptomThreshold &&
        leftHandPresent &&
        rightHandPresent) {
      highMetricsCount++;
    }

    _potentialSymptomsDetected =
        highMetricsCount >= 2; // Example: 2 or more metrics are high
  }

  // Helper to extract history for a specific hand
  List<List<Map<String, double>>?> _getHandHistory(String handedness) {
    List<List<Map<String, double>>?> history = [];
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

  // Calculate distance between two points (null safe)
  double _calculateDistance(Map<String, double>? p1, Map<String, double>? p2) {
    if (p1 == null || p2 == null) return 0.0;
    double dx = (p1['x'] ?? 0.0) - (p2['x'] ?? 0.0);
    double dy = (p1['y'] ?? 0.0) - (p2['y'] ?? 0.0);
    // Ignore Z for simplicity
    return math.sqrt(dx * dx + dy * dy);
  }

  // Calculate speed variance for a landmark index (null safe)
  double _calculateSpeedVariance(
      List<List<Map<String, double>>?> history, int landmarkIndex) {
    List<double> displacements = [];
    for (int i = 1; i < history.length; i++) {
      final List<Map<String, double>>? prevFrameLms = history[i - 1];
      final List<Map<String, double>>? currFrameLms = history[i];

      // Ensure both frames and the landmark exist
      if (prevFrameLms != null &&
          currFrameLms != null &&
          prevFrameLms.length > landmarkIndex &&
          currFrameLms.length > landmarkIndex) {
        final Map<String, double>? prevPoint = prevFrameLms[landmarkIndex];
        final Map<String, double>? currPoint = currFrameLms[landmarkIndex];
        // Check points are not null before calculating distance
        if (prevPoint != null && currPoint != null) {
          displacements.add(_calculateDistance(prevPoint, currPoint));
        }
      }
    }
    if (displacements.length < 2) return 0.0;
    return _calculateVariance(
        displacements); // Variance calc handles normalization
  }

  // Calculate tremor score (std dev of position in a window) (null safe)
  double _calculateTremorScore(List<List<Map<String, double>>?> history,
      int landmarkIndex, int windowSize) {
    if (history.length < windowSize) return 0.0;

    List<double> xCoords = [];
    List<double> yCoords = [];
    // Use the last 'windowSize' frames
    int start = history.length - windowSize;
    for (int i = start; i < history.length; i++) {
      final List<Map<String, double>>? frameLms = history[i];
      // Check frame and landmark exist
      if (frameLms != null && frameLms.length > landmarkIndex) {
        final Map<String, double>? point = frameLms[landmarkIndex];
        // Check point is not null before accessing coordinates
        if (point != null) {
          xCoords.add(point['x'] ?? 0.0);
          yCoords.add(point['y'] ?? 0.0);
        }
      }
    }

    if (xCoords.length < 2 || yCoords.length < 2) return 0.0;

    double stdDevX = _calculateStdDev(xCoords);
    double stdDevY = _calculateStdDev(yCoords);

    // Combine std dev and normalize (heuristic) - requires tuning
    // Factor adjusted based on typical coordinate range (0-1)
    return ((stdDevX + stdDevY) / 2.0 * 15.0).clamp(0.0, 1.0); // Tuned factor
  }

  // Basic variance calculation with normalization
  double _calculateVariance(List<double> data) {
    if (data.length < 2) return 0.0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    double sumOfSquares = data
        .map((x) => math.pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    double variance = sumOfSquares / data.length;
    // Normalize heuristically - variance of displacements (0-1 range)
    // Max expected variance might be around 0.01 if movement is large+fast? Tune this.
    return (variance / 0.01).clamp(0.0, 1.0);
  }

  // Basic standard deviation calculation
  double _calculateStdDev(List<double> data) {
    if (data.length < 2) return 0.0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    double sumOfSquares = data
        .map((x) => math.pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    double variance = sumOfSquares / data.length;
    return math.sqrt(variance);
  }

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

  String _formatLandmarks(List<dynamic> landmarks) {
    if (landmarks.isEmpty) {
      return 'No landmark data.';
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < landmarks.length; i++) {
      final dynamic handDataRaw = landmarks[i];
      if (handDataRaw is Map) {
        // Defensive casting
        final Map<String, dynamic> handData =
            Map<String, dynamic>.from(handDataRaw);
        final String handedness =
            handData['handedness'] as String? ?? 'Unknown';
        final List<dynamic>? landmarkListRaw = handData['landmarks'] as List?;

        buffer.writeln('Hand ${i + 1} ($handedness):');

        if (landmarkListRaw != null && landmarkListRaw is List) {
          for (int j = 0; j < landmarkListRaw.length; j++) {
            final dynamic landmarkDataRaw = landmarkListRaw[j];
            if (landmarkDataRaw is Map) {
              try {
                final Map<String, double> landmarkData =
                    Map<String, double>.from(landmarkDataRaw);
                final double? x = landmarkData['x'];
                final double? y = landmarkData['y'];
                final double? z = landmarkData['z'];
                buffer.writeln(
                    '  Lm $j: (x: ${x?.toStringAsFixed(2) ?? 'N/A'}, ' // Shorter format
                    'y: ${y?.toStringAsFixed(2) ?? 'N/A'}, '
                    'z: ${z?.toStringAsFixed(2) ?? 'N/A'})');
              } catch (e) {
                buffer.writeln('  Lm $j: Error casting coords');
              }
            } else {
              buffer.writeln(
                  '  Lm $j: Invalid format ${landmarkDataRaw.runtimeType}');
            }
          }
        } else {
          buffer.writeln('  Landmark list format error or missing.');
        }
      } else {
        buffer.writeln(
            'Hand ${i + 1}: Invalid data format ${handDataRaw.runtimeType}');
      }
      if (i < landmarks.length - 1) {
        buffer.writeln(); // Add space between hands
      }
    }
    return buffer.toString();
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
                          Text(
                            _formatLandmarks(_landmarks), // Updated formatting
                            style: const TextStyle(
                                fontSize: 10, // Adjusted size
                                fontFamily: 'monospace',
                                color: Colors.white),
                          ),
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
