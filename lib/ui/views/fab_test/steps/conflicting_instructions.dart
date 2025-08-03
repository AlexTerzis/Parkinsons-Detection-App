import 'dart:async';
import 'package:flutter/material.dart';

class ConflictingInstructionsStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const ConflictingInstructionsStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<ConflictingInstructionsStep> createState() => _ConflictingInstructionsStepState();
}

class _ConflictingInstructionsStepState extends State<ConflictingInstructionsStep> {
  static const List<int> _trainingSequence = [1, 1, 1, 2, 2, 2];
  static const List<int> _testSequence = [1, 1, 2, 1, 2, 2, 2, 1, 1, 2];

  int _index = -1;
  int _current = 0;
  int _tapCount = 0;
  int _errors = 0;
  int _sameStreak = 0;
  bool _testDone = false;
  int _phase = 0; // 0 = instructions, 1 = training, 2 = main test
  Timer? _timer;
  bool _showNumber = true;
  bool _waitingToStart = false;

  // Feedback state
  String _lastFeedback = "";
  Color _feedbackColor = Colors.transparent;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextPhase() {
    _timer?.cancel();
    if (_phase == 0) {
      setState(() {
        _phase = 1;
        _index = -1;
        _tapCount = 0;
        _testDone = false;
        _waitingToStart = true;
        _lastFeedback = "";
      });
    } else if (_phase == 1) {
      setState(() {
        _phase = 2;
        _index = -1;
        _errors = 0;
        _sameStreak = 0;
        _tapCount = 0;
        _testDone = false;
        _waitingToStart = true;
        _lastFeedback = "";
      });
    } else if (_phase == 2) {
      _finish();
    }
  }

  void _startPhase() {
    setState(() {
      _waitingToStart = false;
      _index = -1;
      _tapCount = 0;
      _testDone = false;
      _lastFeedback = "";
      _showNumber = true;
    });
    _next();
  }

  void _recordAnswer() {
    if (_testDone || !_showNumber) return;
    setState(() => _tapCount++);
  }

  void _next() {
    _timer?.cancel();

    int? stim;
    int? expected;
    String feedback = '';
    Color feedbackColor = Colors.transparent;

    // Training feedback
    if (_phase == 1 && _index >= 0 && !_testDone) {
      stim = _trainingSequence[_index];
      expected = stim == 1 ? 2 : 1;
      if (_tapCount == expected) {
        feedback = "Σωστό!";
        feedbackColor = Colors.green;
      } else if (stim == 1 && _tapCount != 2) {
        feedback = "Λάθος: Έπρεπε να πατήσετε 2 φορές.";
        feedbackColor = Colors.red;
      } else if (stim == 2 && _tapCount != 1) {
        feedback = "Λάθος: Έπρεπε να πατήσετε 1 φορά.";
        feedbackColor = Colors.red;
      }
    }

    // Main test feedback + error counting (no visible feedback)
    if (_phase == 2 && _index >= 0 && !_testDone) {
      stim = _testSequence[_index];
      expected = stim == 1 ? 2 : 1;
      if (_tapCount != expected) _errors++;
      if (_tapCount == stim) {
        _sameStreak++;
      } else {
        _sameStreak = 0;
      }
    }

    setState(() {
      _showNumber = false;
      if (_phase == 1) {
        _lastFeedback = feedback;
        _feedbackColor = feedbackColor;
      } else {
        _lastFeedback = "";
        _feedbackColor = Colors.transparent;
      }
      _index += 1;
      if ((_phase == 1 && _index >= _trainingSequence.length) ||
          (_phase == 2 && _index >= _testSequence.length)) {
        _testDone = true;
        _current = 0;
      } else {
        _current = _phase == 1 ? _trainingSequence[_index] : _testSequence[_index];
        _tapCount = 0;
      }
    });

    // Blinking logic: 400ms blank, then show number for correct phase duration
    if ((_phase == 1 || _phase == 2) && !_testDone) {
      _timer = Timer(const Duration(milliseconds: 400), () {
        setState(() => _showNumber = true);
        final showDuration = _phase == 1 ? 2200 : 1500;
        _timer = Timer(Duration(milliseconds: showDuration), _next);
      });
    }
  }

  void _finish() {
    _timer?.cancel();
    int score = 0;
    if (_phase == 2) {
      if (_sameStreak >= 4) {
        score = 0;
      } else if (_errors == 0) {
        score = 3;
      } else if (_errors <= 2) {
        score = 2;
      } else {
        score = 1;
      }
    }
    widget.onScored(score);
    widget.onNext();
  }

  String instructions = '''
Οδηγίες:
Όταν εμφανίζεται ο αριθμός 1, πατήστε το κουμπί **δύο** φορές.
Όταν εμφανίζεται ο αριθμός 2, πατήστε το κουμπί **μία** φορά.
''';

  String trainLabel = '''
Δοκιμαστική σειρά:
1 → Πατάω 2 φορές
2 → Πατάω 1 φορά
Ακολουθήστε τις οδηγίες για να καταλάβετε τη λογική του τεστ.
''';

  String Label = '''
1 → Πατάω 2 φορές
2 → Πατάω 1 φορά''';

  String testLabel = '''
Κύρια δοκιμασία:
Όταν δείτε 1 → Πατήστε 2 φορές
Όταν δείτε 2 → Πατήστε 1 φορά
''';

  String resultMessage() {
    if (_sameStreak >= 4) {
      return "Σκορ: 0\nΑπαντήσατε ίδιο αριθμό με το ερέθισμα τουλάχιστον 4 συνεχόμενες φορές.";
    } else if (_errors == 0) {
      return "Σκορ: 3\nΔεν κάνατε κανένα λάθος!";
    } else if (_errors <= 2) {
      return "Σκορ: 2\nΚάνατε 1 ή 2 λάθη.";
    } else {
      return "Σκορ: 1\nΚάνατε περισσότερα από 2 λάθη.";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show result card at the end
    if (_phase == 2 && _testDone) {
      return Scaffold(
        appBar: AppBar(title: const Text('Εναντιούμενα παραγγέλματα')),
        body: Center(
          child: Card(
            color: Colors.white,
            elevation: 8,
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Αποτελέσματα", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  Text(resultMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color:Colors.blueAccent)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _finish,
                    child: const Text("Επόμενο"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Εναντιούμενα παραγγέλματα')),
      body: Stack(
        children: [
          // Instructions phase
          if (_phase == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      instructions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _nextPhase,
                      child: const Text('Έναρξη'),
                    ),
                  ],
                ),
              ),
            ),
          // Before training: trainLabel only
          if (_phase == 1 && _waitingToStart)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      trainLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startPhase,
                      child: const Text('Έναρξη'),
                    ),
                  ],
                ),
              ),
            ),
          // Before actual test: testLabel only
          if (_phase == 2 && _waitingToStart)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      testLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startPhase,
                      child: const Text('Έναρξη'),
                    ),
                  ],
                ),
              ),
            ),
          // During training or actual test: Label + the test UI
          if ((_phase == 1 || _phase == 2) && !_waitingToStart)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      Label,
                      style: const TextStyle(
                        fontSize: 19,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    (_testDone || !_showNumber) ? '' : '$_current',
                    style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _testDone ? null : _recordAnswer,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 110),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Πάτημα', style: TextStyle(fontSize: 36, color: Colors.white)),
                  ),
                  const SizedBox(height: 28),
                  if (_phase == 1 && _lastFeedback.isNotEmpty)
                    Text(
                      _lastFeedback,
                      style: TextStyle(
                        fontSize: 22,
                        color: _feedbackColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          // Hide bottom-right button during result screen for clean UX
          if (!(_phase == 2 && _testDone))
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (_waitingToStart) {
                      _startPhase();
                    } else if (_phase == 2 && _testDone) {
                      _finish();
                    } else {
                      _nextPhase();
                    }
                  },
                  child: Text(_waitingToStart ? 'Έναρξη' : 'Επόμενο'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
