import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NeuroStep1 extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(int score) onScored;

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
  int _thumbsUpCount = 0;
  final int _threshold = 3;
  bool _thumbsUpOverlay = false;
  bool _success = false;

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
      _thumbsUpOverlay = false;
      _success = false;
      _thumbsUpCount = 0;
    });
    _timeout = Timer(const Duration(minutes: 1), () => _finish(false));
  }

  void _finish(bool success) {
    if (_testEnded) return;
    _testEnded = true;
    _timeout?.cancel();
    _timeout = null;
    widget.onScored(success ? 1 : 0);
    setState(() {
      _success = success;
      _thumbsUpOverlay = false;
    });
    if (_channel != null) {
      _channel!.setMethodCallHandler(null);
      _channel = null;
    }
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
        if (gestures.isNotEmpty && gestures.any((g) => g != null && g != 'None')) {
          if (gestures.contains('Thumb_Up')) {
            _thumbsUpCount++;
            setState(() => _thumbsUpOverlay = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!_testEnded) setState(() => _thumbsUpOverlay = false);
            });
            if (_thumbsUpCount >= _threshold) {
              _finish(true);
            }
          } else {
            _thumbsUpCount = 0;
            setState(() => _thumbsUpOverlay = false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PERMISSION VIEW
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Κίνηση αντίχειρα')),
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
        appBar: AppBar(title: const Text('Κίνηση αντίχειρα')),
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
                child: const Text(
                  'Όταν πατήσετε "Έναρξη", θα ενεργοποιηθεί η κάμερα για 1 λεπτό.\n\n'
                  'Δείξτε "thumbs up" στο χέρι σας μπροστά στην κάμερα για να προχωρήσετε.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, color: Colors.white),
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

    // TEST PHASE (camera + overlays, NO gap, instructions always visible)
    if (!_testEnded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AndroidView(
                viewType: 'gesture_recognizer_view',
                layoutDirection: TextDirection.ltr,
                onPlatformViewCreated: _onViewCreated,
              ),
            ),
            // Always visible instructions overlay
            Positioned(
              left: 24,
              right: 24,
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800]?.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  'Δείξτε "thumbs up" στο χέρι σας μπροστά στην κάμερα.\nΈχετε 1 λεπτό για να πετύχετε!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, color: Colors.white),
                ),
              ),
            ),
            // Detected overlay (only for 0.8s when detected, does not hide instructions)
            if (_thumbsUpOverlay)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.green[700]!.withOpacity(0.91),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: const Text(
                    '👍 Detected!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Fake AppBar/title (optional, comment out if you want totally immersive!)
            Positioned(
              left: 0, right: 0, top: 0,
              child: Container(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                color: Colors.black.withOpacity(0.6),
                alignment: Alignment.centerLeft,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      'Κίνηση αντίχειρα',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // POST-TEST RESULT (NO camera, just result overlay, styled like intro)
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _success
                ? Colors.green[800]?.withOpacity(0.93)
                : Colors.red[800]?.withOpacity(0.93),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_success ? Icons.check_circle_outline : Icons.error_outline,
                  size: 66,
                  color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _success
                    ? 'Συγχαρητήρια! Αναγνωρίστηκε "thumbs up".'
                    : 'Δεν αναγνωρίστηκε "thumbs up" μέσα στο χρονικό όριο.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _success ? Colors.green[900] : Colors.red[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
                  textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),
                child: const Text('Συνέχεια'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
