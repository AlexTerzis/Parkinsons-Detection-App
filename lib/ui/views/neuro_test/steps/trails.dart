import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class TrailsStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;

  const TrailsStep({super.key, required this.onNext, required this.onScored});

  @override
  State<TrailsStep> createState() => _TrailsStepState();
}

class _TrailsStepState extends State<TrailsStep> {
  final sequence = ['1', 'Α', '2', 'Β', '3', 'Γ', '4', 'Δ', '5', 'Ε'];
  int currentIndex = 0;
  List<Offset> drawnLines = [];
  late Map<String, Offset> anchorPoints;

  final double circleSize = 60;
  bool testCompleted = false;
  late Timer timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAnchorPoints(context);
      timeoutTimer = Timer(const Duration(minutes: 2), () {
        if (!testCompleted) {
          widget.onScored(0);
          widget.onNext();
        }
      });
    });
  }

  @override
  void dispose() {
    if (timeoutTimer.isActive) timeoutTimer.cancel();
    super.dispose();
  }

  void completeTestWithPoint() {
    if (!testCompleted) {
      testCompleted = true;
      timeoutTimer.cancel();
      widget.onScored(1);
      widget.onNext();
    }
  }

  void _generateAnchorPoints(BuildContext context) {
  final rand = Random();
  final size = MediaQuery.of(context).size;

  const double safePadding = 32.0;
  const double topMargin = 40.0;
  const double bottomMargin = 400.0;
  const double minDistance = 100.0;

  final usableWidth = size.width - 2 * safePadding;
  final usableHeight = size.height - topMargin - bottomMargin;

  final List<Offset> usedPoints = [];
  final Map<String, Offset> result = {};
  final Set<String> usedLabels = {};

  for (final label in sequence) {
    if (usedLabels.contains(label)) continue;

    Offset candidate = const Offset(0, 0);
    bool overlaps;
    int attempts = 0;

    do {
      if (++attempts > 1000) break;

      candidate = Offset(
        rand.nextDouble() * usableWidth + safePadding,
        rand.nextDouble() * usableHeight + topMargin,
      );

      overlaps = usedPoints.any((p) => (p - candidate).distance < minDistance);
    } while (overlaps);

    usedLabels.add(label);
    usedPoints.add(candidate);
    result[label] = candidate;
  }

  setState(() => anchorPoints = result);
}


  void handleTap(String label) {
    if (label == sequence[currentIndex]) {
      setState(() {
        if (currentIndex > 0) {
          drawnLines.add(anchorPoints[sequence[currentIndex - 1]]!);
          drawnLines.add(anchorPoints[label]!);
        }
        currentIndex++;
      });

      if (currentIndex == sequence.length) {
        Future.delayed(const Duration(milliseconds: 500), completeTestWithPoint);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Λάθος σειρά.')),
      );
    }
  }

  Widget _buildCircle(String label, Offset pos) {
    return Positioned(
      left: pos.dx - circleSize / 2,
      top: pos.dy - circleSize / 2,
      child: GestureDetector(
        onTap: () => handleTap(label),
        child: Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: sequence.indexOf(label) < currentIndex ? Colors.green : Colors.white,
            border: Border.all(color: const Color.fromARGB(255, 44, 33, 96), width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Οπτικο-Νοητική Ιχνηλάτηση'),
      automaticallyImplyLeading: true,
      centerTitle: true,
      ),
      
      // ignore: unnecessary_null_comparison
      body: anchorPoints == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Οδηγίες:\nΣυνδέστε τα κυκλάκια ξεκινώντας από το 1, έπειτα το Α, μετά το 2, Β, 3, Γ... έως το 5 και Ε.\n'
                    'Αν κάνετε λάθος, μπορείτε να προσπαθήσετε ξανά. Αν δυσκολεύεστε, πατήστε "Επόμενο". Χρόνος 2 λεπτά.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: LinePainter(drawnLines),
                        child: Container(),
                      ),
                      ...anchorPoints.entries.map((e) => _buildCircle(e.key, e.value)).toList(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (!testCompleted) {
                        timeoutTimer.cancel();
                        widget.onScored(0);
                        widget.onNext();
                      }
                    },
                    child: const Text('Επόμενο (παράλειψη)'),
                  ),
                ),
              ],
            ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<Offset> points;
  LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4;

    for (int i = 0; i < points.length - 1; i += 2) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}