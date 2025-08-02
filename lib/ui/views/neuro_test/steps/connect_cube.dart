import 'package:flutter/material.dart';
import 'dart:async';

class ConnectCubeStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(double) onScored;

  const ConnectCubeStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<ConnectCubeStep> createState() => _ConnectCubeStepState();
}

class _ConnectCubeStepState extends State<ConnectCubeStep> {
  final Set<String> connectedPairs = {};
  final Set<String> incorrectPairs = {};
  int? selectedPoint;
  bool showHint = false;
  Timer? hintTimer;
  Timer? timeoutTimer;
  bool testCompleted = false;
  bool usedHint = false;

  final Set<String> expectedEdges = {
    '0-1', '0-2', '1-3', '2-3',
    '4-5', '4-6', '5-7', '6-7',
    '0-4', '1-5', '2-6', '3-7'
  };

  @override
  void initState() {
    super.initState();
    _triggerHint(initial: true);
    timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!testCompleted) {
        widget.onScored(0);
        widget.onNext();
      }
    });
  }

  @override
  void dispose() {
    hintTimer?.cancel();
    timeoutTimer?.cancel();
    super.dispose();
  }

  void handlePointTap(int index, List<Offset> points) {
    final messenger = ScaffoldMessenger.of(context);

    if (selectedPoint == null) {
      setState(() => selectedPoint = index);
      return;
    }
    if (selectedPoint == index) {
      setState(() => selectedPoint = null);
      return;
    }

    final a = selectedPoint!;
    final b = index;
    final pair = [a, b]..sort();
    final key = '${pair[0]}-${pair[1]}';
    final isExpected = expectedEdges.contains(key);

    bool justWrong = false;

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

    messenger.hideCurrentSnackBar();

    if (justWrong) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Λάθος γραμμή')),
      );
    }

    final hasAll = expectedEdges.every(connectedPairs.contains);
    final hasSomeWrong = incorrectPairs.isNotEmpty;

    if (hasAll && !hasSomeWrong && !testCompleted) {
      // perfect completion
      testCompleted = true;
      timeoutTimer?.cancel();
      messenger.showSnackBar(
        SnackBar(
          content: Text(usedHint
              ? 'Σωστό! (Χρησιμοποιήθηκε υπόδειξη)'
              : 'Σωστή απάντηση!'),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        widget.onScored(usedHint ? 0.5 : 1.0);
        widget.onNext();
      });
    } else if (hasAll && hasSomeWrong) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Σχεδόν σωστό—διαγράψτε τις κόκκινες γραμμές')),
      );
    }
  }

  void _triggerHint({bool initial = false}) {
    setState(() {
      showHint = true;
      if (!initial) usedHint = true;
    });
    hintTimer?.cancel();
    hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive centering and scaling
    final size = MediaQuery.of(context).size;
    final double cubeWidth = size.width * 0.45;
    final double cubeHeight = size.width * 0.45;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2 - 40; // slightly up

    // Cube "base" is 4x4 grid (spacing)
    final spacing = cubeWidth / 3;
    final layerGap = spacing * 0.8;

    final List<Offset> points = [
      // Back square (lower layer)
      Offset(centerX - spacing, centerY - spacing), // 0
      Offset(centerX + spacing, centerY - spacing), // 1
      Offset(centerX - spacing, centerY + spacing), // 2
      Offset(centerX + spacing, centerY + spacing), // 3
      // Front square (upper layer)
      Offset(centerX - spacing + layerGap, centerY - spacing + layerGap), // 4
      Offset(centerX + spacing + layerGap, centerY - spacing + layerGap), // 5
      Offset(centerX - spacing + layerGap, centerY + spacing + layerGap), // 6
      Offset(centerX + spacing + layerGap, centerY + spacing + layerGap), // 7
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Οπτικο-Κατασκευαστικές Ικανότητες')),
      body: Stack(
        children: [
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
          ...points.asMap().entries.map((e) {
            final idx = e.key;
            final pos = e.value;
            return Positioned(
              left: pos.dx - 16,
              top: pos.dy - 16,
              child: GestureDetector(
                onTap: () => handlePointTap(idx, points),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedPoint == idx
                        ? Colors.blue.withOpacity(0.2)
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
                      usedHint = false;
                    });
                  },
                  child: const Text('Καθαρισμα'),
                ),
                ElevatedButton(
                  onPressed: () => _triggerHint(),
                  child: const Text('Υπόδειξη'),
                ),
                ElevatedButton(
                  onPressed: () {
                    timeoutTimer?.cancel();
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

    for (final key in connections) {
      final idx = key.split('-').map(int.parse).toList();
      final p1 = points[idx[0]];
      final p2 = points[idx[1]];
      final paint = incorrect.contains(key) ? wrongPaint : correctPaint;
      canvas.drawLine(p1, p2, paint);
    }

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
