import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NeuroStep1 extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(double score) onScored; // score is now double

  const NeuroStep1({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  State<NeuroStep1> createState() => _NeuroStep1State();
}

class _NeuroStep1State extends State<NeuroStep1> {
  MethodChannel? _channel;
  Timer? _timeout;
  bool _hasPermission = false;
  bool _askedPermission = false;
  bool _testStarted = false;
  bool _testEnded = false;
  bool _success = false;

  // Gesture detection maps
  final Map<String, int> _gestureCounts = {
    'Thumb_Up': 0,
    'Open_Palm': 0,
    'Pointing_Up': 0,
    'Closed_Fist': 0,
  };
  final Map<String, bool> _gestureDone = {
    'Thumb_Up': false,
    'Open_Palm': false,
    'Pointing_Up': false,
    'Closed_Fist': false,
  };
  String? _lastDetectedGesture; // For overlay

  static const int _framesNeeded = 4;

  // GESTURE display names for the overlay and instructions
  static const gestureLabels = {
    'Thumb_Up': '👍 Thumbs Up',
    'Open_Palm': '🖐️ Open Palm',
    'Pointing_Up': '☝️ Pointing Up',
    'Closed_Fist': '✊ Closed Fist',
  };

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      _askedPermission = true;
    }
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  void _startTest() {
    setState(() {
      _testStarted = true;
      _testEnded = false;
      _success = false;
      _lastDetectedGesture = null;
      for (final key in _gestureCounts.keys) {
        _gestureCounts[key] = 0;
        _gestureDone[key] = false;
      }
    });
    _timeout = Timer(const Duration(minutes: 1), () => _finish());
  }

  void _finish() async {
    if (_testEnded) return;
    _testEnded = true;
    _timeout?.cancel();
    _timeout = null;

    final double score = _gestureDone.values.where((v) => v).length * 0.75;
    widget.onScored(score);
    setState(() {
      _success = score == 3.0;
    });

    if (_channel != null) {
      _channel!.setMethodCallHandler(null);
      _channel = null;
    }
    // Wait a bit so user sees overlay
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _success
            ? Colors.green[800]?.withOpacity(0.97)
            : Colors.blueGrey[800]?.withOpacity(0.97),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(
              _success ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(width: 12),
            Text(
              _success ? 'Επιτυχία!' : 'Ολοκληρώθηκε',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          _success
              ? 'Συγχαρητήρια! Εντοπίστηκαν όλα τα gestures.\n\nΣκορ: 3.00/3.00'
              : 'Ολοκληρώθηκε ο χρόνος.\nΣκορ: ${score.toStringAsFixed(2)}/3.00',
          style: const TextStyle(fontSize: 19, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Συνέχεια', style: TextStyle(fontSize: 19)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    if (_channel != null) {
      _channel!.setMethodCallHandler(null);
      _channel = null;
    }
    super.dispose();
  }

  void _onViewCreated(int id) {
    _channel = MethodChannel('gesture_recognizer_channel_$id');
    _channel!.setMethodCallHandler((call) async {
      if (_testEnded) return;
      if (call.method == 'onGestures') {
        final List<dynamic> gestures = call.arguments;
        bool updated = false;
        for (final g in _gestureCounts.keys) {
          if (_gestureDone[g]!) continue; // skip if already done
          if (gestures.contains(g)) {
            _gestureCounts[g] = _gestureCounts[g]! + 1;
            if (_gestureCounts[g]! >= _framesNeeded) {
              _gestureDone[g] = true;
              _lastDetectedGesture = g;
              updated = true;
              // Show overlay for a second when a gesture is done
              setState(() {});
              Future.delayed(const Duration(milliseconds: 900), () {
                if (!_testEnded) setState(() => _lastDetectedGesture = null);
              });
            }
          } else {
            _gestureCounts[g] = 0;
          }
        }
        // If all gestures are done, finish!
        if (_gestureDone.values.every((v) => v)) {
          _finish();
        } else if (updated) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PERMISSION VIEW
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Αναγνώριση Χειρονομιών')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Απαιτείται πρόσβαση στην κάμερα για να συνεχίσετε.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Επανέλεγχος άδειας'),
              ),
              if (_askedPermission)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Ελέγξτε τις ρυθμίσεις της εφαρμογής αν το πρόβλημα παραμένει.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // PRE-TEST VIEW
    if (!_testStarted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Αναγνώριση Χειρονομιών')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800]?.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 19, color: Colors.white),
                    children: [
                      TextSpan(text: 'Όταν πατήσετε "Έναρξη", θα ενεργοποιηθεί η κάμερα για 1 λεπτό.\n\nΠρέπει να πραγματοποιήσετε τις εξής κινήσεις:\n\n'),
                      TextSpan(text: '👍 Thumbs Up\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '🖐️ Open Palm\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '☝️ Pointing Up\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '✊ Closed Fist', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(fontSize: 21),
                ),
                child: const Text('Έναρξη'),
              ),
            ],
          ),
        ),
      );
    }

    // TEST PHASE (camera + overlays)
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen camera view
          SizedBox.expand(
            child: AndroidView(
              viewType: 'gesture_recognizer_view',
              layoutDirection: TextDirection.ltr,
              onPlatformViewCreated: _onViewCreated,
            ),
          ),
          // Instructions overlay (always visible, with progress)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 18, left: 22, right: 22),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800]?.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Εκτελέστε όλες τις κινήσεις. Κάθε φορά που αναγνωρίζεται μία, θα σημειώνεται παρακάτω.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    ..._gestureCounts.keys.map((g) {
                      final done = _gestureDone[g]!;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            gestureLabels[g]!,
                            style: TextStyle(
                              color: done ? Colors.greenAccent : Colors.white,
                              fontWeight: done ? FontWeight.bold : FontWeight.normal,
                              fontSize: 19,
                            ),
                          ),
                          if (done)
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                            ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          // Detected overlay (for each gesture)
          if (_lastDetectedGesture != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.green[700]!.withOpacity(0.91),
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Text(
                  '${gestureLabels[_lastDetectedGesture!]}\nΑναγνωρίστηκε!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Fake AppBar/title (optional)
          ],
      ),
    );
  }
}
