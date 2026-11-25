import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkinsondetetion/models/frame_data.dart';
import 'package:parkinsondetetion/services/landmark_parser.dart';
import 'package:permission_handler/permission_handler.dart';

// [FrameData] and [LandmarkData] are plain models rather than definitions on
// this widget, so that services can classify frames without importing a piece
// of UI. Re-exported because the ViewModel and its tests already refer to them
// through this file.
export 'package:parkinsondetetion/models/frame_data.dart';

/// Live camera preview with hand-landmark detection.
///
/// Deliberately nothing more than that. This widget parses frames and hands
/// them to [onFrame]; it renders no metrics, no scores and no interpretation of
/// what it sees.
///
/// It used to. An earlier version kept a rolling 30-frame history, ran the
/// whole [HandMetrics] suite over it inside `setState` on every frame, and drew
/// symptom bars plus a "Potential Symptoms Detected" chip over the preview.
/// That was removed for two independent reasons:
///
/// * It presented a diagnosis-shaped verdict to the patient, derived from about
///   one second of movement, while they were still performing the task.
/// * It ran four 21-landmark metric passes synchronously on the UI thread for
///   every frame. That cost capture rate, and capture rate is what the real
///   analysis depends on — below 15 fps `TremorAnalysisService` refuses to
///   report a tremor frequency at all. Removing the overlay measurably improves
///   the recording it was drawn on top of.
///
/// Patient-facing feedback during a run belongs to `CameraTestView`, which
/// knows which task is running and what the patient should be told about it.
class HandLandmarkerScreen extends StatefulWidget {
  const HandLandmarkerScreen({super.key, this.onFrame, this.landscape = false});

  /// Called once per processed frame, whether or not a hand was found.
  final void Function(FrameData)? onFrame;

  /// Locks the screen to landscape for the camera hand test. Other users of
  /// this screen (the posture test) keep the portrait layout.
  final bool landscape;

  @override
  State<HandLandmarkerScreen> createState() => _HandLandmarkerScreenState();
}

class _HandLandmarkerScreenState extends State<HandLandmarkerScreen> {
  /// Only the permission and orientation state drive a rebuild; frames never
  /// do.
  bool _hasPermission = false;

  /// Whether the screen has finished turning to landscape.
  ///
  /// The native camera view is not created until it has. CameraX fixes the
  /// analysis rotation from the display when it binds, so a view created while
  /// the screen was still portrait would start out feeding the detector
  /// sideways frames. The native side also follows later rotations, but
  /// starting in the right orientation avoids a burst of bad first frames.
  bool _orientationReady = false;

  static const LandmarkParser _parser = LandmarkParser();

  @override
  void initState() {
    super.initState();
    _lockLandscape();
    _checkCameraPermission();
  }

  /// The test runs in landscape, with the phone on its side.
  ///
  /// It used to be locked to portrait. With the phone propped up at a
  /// distance, a portrait picture is too narrow for two hands side by side, so
  /// each hand had to be held far from the lens to fit and came out small in
  /// the frame. On its side the picture is wide enough for both hands at a
  /// comfortable distance.
  ///
  /// Locked rather than left free, for the reason the portrait lock existed:
  /// the patient must not be able to turn the picture mid-recording. Either
  /// landscape direction is allowed so the phone can rest on whichever edge
  /// is convenient.
  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(widget.landscape
        ? <DeviceOrientation>[
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : <DeviceOrientation>[DeviceOrientation.portraitUp]);
    // One frame for the window to actually turn before the camera binds.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _orientationReady = true);
  }

  Future<void> _checkCameraPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    if (mounted) {
      setState(() => _hasPermission = status == PermissionStatus.granted);
    }
  }

  /// Parses one native payload and forwards it.
  ///
  /// No `setState` here: nothing this widget draws depends on the frame, so
  /// rebuilding the preview per frame would be pure cost.
  ///
  /// Nothing is filtered out either — not empty payloads, not hands with too
  /// few landmarks. Deciding what a frame was worth is `TrackingClassifier`'s
  /// job, and it can only classify frames it is given. Dropping the bad ones
  /// here would erase exactly the evidence that a recording went wrong.
  ///
  /// The timestamp is the camera's capture time from the native side, not the
  /// time the message arrived here.
  void _onLandmarksDetected(dynamic payload) {
    if (!mounted) return;

    widget.onFrame?.call(_parser.parseFrame(
      payload,
      fallbackTimestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (!_hasPermission) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera permission is needed for this test.'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkCameraPermission,
              child: const Text('Grant permission'),
            ),
          ],
        ),
      );
    } else if (!_orientationReady) {
      body = const ColoredBox(color: Colors.black, child: SizedBox.expand());
    } else {
      body = HandLandmarkerView(onLandmarksDetected: _onLandmarksDetected);
    }
    return Scaffold(appBar: null, body: body);
  }

  @override
  void dispose() {
    // Back to the app's normal portrait layout for whatever comes next — the
    // results screen included.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

/// Hosts the native detector view and relays its landmark callbacks.
class HandLandmarkerView extends StatefulWidget {
  const HandLandmarkerView({super.key, required this.onLandmarksDetected});

  /// Receives the raw native payload; see `LandmarkParser.parseFrame`.
  final void Function(dynamic) onLandmarksDetected;

  @override
  State<HandLandmarkerView> createState() => _HandLandmarkerViewState();
}

class _HandLandmarkerViewState extends State<HandLandmarkerView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'hand_landmarker_view',
      layoutDirection: TextDirection.ltr,
      onPlatformViewCreated: _onViewCreated,
    );
  }

  void _onViewCreated(int id) {
    // Ensure the channel name matches the one used in HandLandmarkerView.kt
    _channel = MethodChannel('hand_landmarker_channel_$id');
    _channel!.setMethodCallHandler((call) async {
      if (call.method != 'onLandmarks') {
        debugPrint('Unknown method call: ${call.method}');
        return;
      }
      try {
        // An empty hand list is a real result — the frame was processed and
        // held no hands — so it is forwarded rather than swallowed.
        widget.onLandmarksDetected(call.arguments);
      } catch (e, stacktrace) {
        debugPrint('Error processing landmarks: $e');
        debugPrint('$stacktrace');
        widget.onLandmarksDetected(const <dynamic>[]);
      }
    });
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
