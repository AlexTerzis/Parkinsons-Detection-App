import 'package:flutter/material.dart';
import 'dart:async';

class NeuroStep3 extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int) onScored;

  const NeuroStep3({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<NeuroStep3> createState() => _NeuroStep3State();
}

class _NeuroStep3State extends State<NeuroStep3> {
  final List<Offset> points = [
    const Offset(100, 100), // 0
    const Offset(200, 100), // 1
    const Offset(100, 200), // 2
    const Offset(200, 200), // 3
    const Offset(140, 140), // 4
    const Offset(240, 140), // 5
    const Offset(140, 240), // 6
    const Offset(240, 240), // 7
  ];

  final Set<String> connectedPairs = {};
  final Set<String> incorrectPairs = {};
  int? selectedPoint;
  bool showHint = true;
  late Timer hintTimer;
  late Timer timeoutTimer;
  bool testCompleted = false;

  final Set<String> expectedEdges = {
    '0-1', '0-2', '1-3', '2-3',
    '4-5', '4-6', '5-7', '6-7',
    '0-4', '1-5', '2-6', '3-7'
  };

  @override
  void initState() {
    super.initState();
    hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showHint = false);
    });
    timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!testCompleted) {
        widget.onScored(0);
        widget.onNext();
      }
    });
  }

  @override
  void dispose() {
    hintTimer.cancel();
    timeoutTimer.cancel();
    super.dispose();
  }

  void handlePointTap(int index) {
    final messenger = ScaffoldMessenger.of(context);

    // 1) select / deselect dots
    if (selectedPoint == null) {
      setState(() => selectedPoint = index);
      return;
    }
    if (selectedPoint == index) {
      setState(() => selectedPoint = null);
      return;
    }

    // 2) two distinct taps → form key
    final a = selectedPoint!;
    final b = index;
    final pair = [a, b]..sort();
    final key = '${pair[0]}-${pair[1]}';
    final isExpected = expectedEdges.contains(key);

    bool justWrong = false;

    // 3) update state
    setState(() {
      if (connectedPairs.contains(key)) {
        connectedPairs.remove(key);
        incorrectPairs.remove(key);
      } else {
        connectedPairs.add(key);
        if (!isExpected) {
          incorrectPairs.add(key);
          justWrong = true;
        }
      }
      selectedPoint = null;
    });

    // clear any existing snackbars immediately
    messenger.hideCurrentSnackBar();

    // 4) wrong-line feedback
    if (justWrong) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Λάθος γραμμή')),
      );
    }

    // 5) check for completion
    final hasAll = expectedEdges.every(connectedPairs.contains);
    final hasSomeWrong = incorrectPairs.isNotEmpty;

    if (hasAll && !hasSomeWrong && !testCompleted) {
      // perfect completion
      testCompleted = true;
      timeoutTimer.cancel();
      messenger.showSnackBar(
        const SnackBar(content: Text('Σωστή απάντηση!')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        widget.onScored(1);
        widget.onNext();
      });
    } else if (hasAll && hasSomeWrong) {
      // almost there—red lines still present
      messenger.showSnackBar(
        const SnackBar(content: Text('Σχεδόν εκεί—διαγράψτε τις κόκκινες γραμμές')),
      );
    }
  }

  bool _hasCompletedCubePerfectly() {
    return expectedEdges.every(connectedPairs.contains) && incorrectPairs.isEmpty;
  }

  void triggerHint() {
    setState(() => showHint = true);
    hintTimer.cancel();
    hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Οπτικο-Κατασκευαστικές Ικανότητες')),
      body: Stack(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Text(
                  'Αντιγράψτε τον κύβο συνδέοντας τις τελείες. '
                  'Πατήστε πρώτα μία τελεία και μετά την επόμενη.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),

          // Full‑screen painter
          Positioned.fill(
            child: CustomPaint(
              painter: LinePainter(
                points,
                connectedPairs,
                incorrectPairs,
                expectedEdges,
                showHint,
              ),
            ),
          ),

          // Dots
          ...points.asMap().entries.map((e) {
            final idx = e.key;
            final pos = e.value;
            return Positioned(
              left: pos.dx - 12,
              top: pos.dy - 12,
              child: GestureDetector(
                onTap: () => handlePointTap(idx),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selectedPoint == idx
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.white,
                    border: Border.all(
                      color: selectedPoint == idx ? Colors.blue : Colors.black,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),

          // Controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      connectedPairs.clear();
                      incorrectPairs.clear();
                      selectedPoint = null;
                    });
                  },
                  child: const Text('Καθαρισμα'),
                ),
                ElevatedButton(
                  onPressed: triggerHint,
                  child: const Text('Υπόδειξη'),
                ),
                ElevatedButton(
                  onPressed: () {
                    timeoutTimer.cancel();
                    widget.onScored(0);
                    widget.onNext();
                  },
                  child: const Text('Επόμενο'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<Offset> points;
  final Set<String> connections;
  final Set<String> incorrect;
  final Set<String> expected;
  final bool showHint;

  LinePainter(
    this.points,
    this.connections,
    this.incorrect,
    this.expected,
    this.showHint,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final correctPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3;
    final wrongPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;
    final hintPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2;

    // Draw confirmed connections
    for (final key in connections) {
      final idx = key.split('-').map(int.parse).toList();
      final p1 = points[idx[0]];
      final p2 = points[idx[1]];
      final paint = incorrect.contains(key) ? wrongPaint : correctPaint;
      canvas.drawLine(p1, p2, paint);
    }

    // Draw hints
    if (showHint) {
      for (final key in expected) {
        final idx = key.split('-').map(int.parse).toList();
        canvas.drawLine(points[idx[0]], points[idx[1]], hintPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
