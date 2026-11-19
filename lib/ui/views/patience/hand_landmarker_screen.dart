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
  const HandLandmarkerScreen({super.key, this.onFrame});

  /// Called once per processed frame, whether or not a hand was found.
  final void Function(FrameData)? onFrame;

  @override
  State<HandLandmarkerScreen> createState() => _HandLandmarkerScreenState();
}

class _HandLandmarkerScreenState extends State<HandLandmarkerScreen> {
  /// Only the permission state drives a rebuild; frames never do.
  bool _hasPermission = false;

  static const LandmarkParser _parser = LandmarkParser();

  @override
  void initState() {
    super.initState();
    // Held in portrait for the whole assessment.
    //
    // The preview used to unlock rotation and then counter-rotate itself with a
    // RotatedBox. The native camera view and the Flutter overlays did not turn
    // together: on a device, turning the phone rotated the instructions but
    // left the video as it was, so the hand appeared lying on its side while
    // the text read upright.
    //
    // Rather than chase that, the test stays portrait. The phone is meant to be
    // propped up and left alone for the duration, the protocol shows one
    // upright hand at a time, and a rotation the patient cannot benefit from is
    // not worth the ways it can go wrong mid-recording.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _checkCameraPermission();
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
  void _onLandmarksDetected(List<dynamic> detectedHandsData) {
    if (!mounted) return;

    widget.onFrame?.call(FrameData(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      hands: _parser.parseHands(detectedHandsData),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      // No RotatedBox and no OrientationBuilder: the screen is portrait-locked,
      // so the native preview and the Flutter overlays are already aligned.
      body: _hasPermission
          ? HandLandmarkerView(onLandmarksDetected: _onLandmarksDetected)
          : Center(
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
            ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

/// Hosts the native detector view and relays its landmark callbacks.
class HandLandmarkerView extends StatefulWidget {
  const HandLandmarkerView({super.key, required this.onLandmarksDetected});

  final Function(List<dynamic>) onLandmarksDetected;

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
        final landmarksData = call.arguments;
        // An empty list is a real result — the frame was processed and held no
        // hands — so it is forwarded rather than swallowed.
        widget.onLandmarksDetected(
          landmarksData is List<dynamic> ? landmarksData : const <dynamic>[],
        );
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
