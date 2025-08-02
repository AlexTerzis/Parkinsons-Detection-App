import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ClockStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(num score) onScored;

  const ClockStep({
    Key? key,
    required this.onNext,
    required this.onScored,
  }) : super(key: key);

  @override
  _ClockStepState createState() => _ClockStepState();
}

enum Hand { hour, minute }

class _ClockStepState extends State<ClockStep> {
  double _hourAngle = -pi / 2;
  double _minuteAngle = -pi / 2;
  bool _hourCorrect = false;
  bool _minuteCorrect = false;
  bool _showHint = false;
  bool _hintUsed = false;
  Hand? _activeHand;
  Timer? _completionTimer, _timeoutTimer, _hintTimer, _greenTimer;
  bool _bothCorrectStable = false;
  bool _shouldShowGreen = false;

  static final _targetHourAngle = ((11 + 10 / 60) * 30) * pi / 180 - pi / 2;
  static final _targetMinuteAngle = (10 * 6) * pi / 180 - pi / 2;
  static const _tolerance = 0.1; // ~6°

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      _proceedWithScore();
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _timeoutTimer?.cancel();
    _hintTimer?.cancel();
    _greenTimer?.cancel();
    super.dispose();
  }

  bool _isClose(double a, double b) {
    double d = (a - b) % (2 * pi);
    if (d < 0) d += 2 * pi;
    if (d > pi) d = 2 * pi - d;
    return d < _tolerance;
  }

  void _onPanStart(DragStartDetails d, Size size) {
    final center = size.center(Offset.zero);
    final hTip = center + Offset(cos(_hourAngle), sin(_hourAngle)) * size.shortestSide * 0.24;
    final mTip = center + Offset(cos(_minuteAngle), sin(_minuteAngle)) * size.shortestSide * 0.32;
    _activeHand = (d.localPosition - hTip).distance < (d.localPosition - mTip).distance
        ? Hand.hour
        : Hand.minute;
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_activeHand == null) return;
    final center = size.center(Offset.zero);
    final ang = atan2(d.localPosition.dy - center.dy, d.localPosition.dx - center.dx);

    bool hourWasCorrect = _hourCorrect;
    bool minuteWasCorrect = _minuteCorrect;

    setState(() {
      if (_activeHand == Hand.hour) {
        _hourAngle = ang;
        _hourCorrect = _isClose(_hourAngle, _targetHourAngle);
      } else {
        _minuteAngle = ang;
        _minuteCorrect = _isClose(_minuteAngle, _targetMinuteAngle);
      }
    });

    _checkBothCorrect();
  }

  void _onPanEnd(_) => _activeHand = null;

  void _checkBothCorrect() {
    if (_hourCorrect && _minuteCorrect && !_bothCorrectStable) {
      // Start the stable timer for 0.5s
      _greenTimer?.cancel();
      _greenTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _bothCorrectStable = true;
          _shouldShowGreen = true;
        });
        _timeoutTimer?.cancel();
        _completionTimer?.cancel();
        _completionTimer = Timer(const Duration(milliseconds: 500), () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_hintUsed
                  ? 'Σωστό! (Χρησιμοποιήθηκε υπόδειξη)'
                  : 'Σωστή απάντηση!'),
            ),
          );
          _proceedWithScore();
        });
      });
    } else if (!_hourCorrect || !_minuteCorrect) {
      // Any hand not correct resets the timer
      _greenTimer?.cancel();
      if (_bothCorrectStable) {
        setState(() {
          _bothCorrectStable = false;
          _shouldShowGreen = false;
        });
      }
    }
  }

  void _proceedWithScore() {
    _timeoutTimer?.cancel();
    _completionTimer?.cancel();
    _greenTimer?.cancel();
    double raw = (_hourCorrect ? 1.5 : 0) + (_minuteCorrect ? 1.5 : 0);
    if (_bothCorrectStable) raw = 3.0;
    final score =(_hintUsed ? raw : raw/2);
    widget.onScored(score < 0 ? 0 : score);
    widget.onNext();
  }

  void _triggerHint() {
    setState(() {
      _showHint = true;
      _hintUsed = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color handColor(bool correct) => (_shouldShowGreen && _bothCorrectStable)
        ? Colors.green
        : Colors.black;

    return Scaffold(
      appBar: AppBar(title: const Text('Ρολόι: δείκτες')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Μετακινήστε τους δείκτες ώστε να δείχνουν 11:10',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (ctx, cons) {
              final size = cons.biggest;
              return Stack(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _onPanStart(d, size),
                  onPanUpdate: (d) => _onPanUpdate(d, size),
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: size,
                    painter: _ClockHandsPainter(
                      hourAngle: _hourAngle,
                      minuteAngle: _minuteAngle,
                      hourColor: handColor(_hourCorrect),
                      minuteColor: handColor(_minuteCorrect),
                      showHint: _showHint,
                      hintHour: _targetHourAngle,
                      hintMinute: _targetMinuteAngle,
                    ),
                  ),
                ),
                // Hint button centered
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _triggerHint,
                      child: const Text('Υπόδειξη'),
                    ),
                  ),
                ),
                // Next in bottom right
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      _proceedWithScore();
                    },
                    child: const Text('Επόμενο'),
                  ),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}

class _ClockHandsPainter extends CustomPainter {
  final double hourAngle, minuteAngle;
  final Color hourColor, minuteColor;
  final bool showHint;
  final double hintHour, hintMinute;

  _ClockHandsPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.hourColor,
    required this.minuteColor,
    required this.showHint,
    required this.hintHour,
    required this.hintMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = min(size.width, size.height) * 0.4;

    // Face
    canvas.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.black);

    // Numbers
    const ts = TextStyle(fontSize: 18, color: Colors.black);
    for (int i = 0; i < 12; i++) {
      final a = (pi / 6) * i - pi / 2;
      final pos = Offset(center.dx + cos(a) * (r - 24),
          center.dy + sin(a) * (r - 24));
      final tp = TextPainter(
        text: TextSpan(text: '${i == 0 ? 12 : i}', style: ts),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Hint lines
    if (showHint) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 4;
      final hh = center + Offset(cos(hintHour), sin(hintHour)) * r * 0.6;
      final hm = center + Offset(cos(hintMinute), sin(hintMinute)) * r * 0.8;
      canvas.drawLine(center, hh, paint);
      canvas.drawLine(center, hm, paint);
    }

    // Hour hand
    canvas.drawLine(
        center,
        center + Offset(cos(hourAngle), sin(hourAngle)) * r * 0.6,
        Paint()
          ..strokeWidth = 6
          ..color = hourColor
          ..strokeCap = StrokeCap.round);

    // Minute hand
    canvas.drawLine(
        center,
        center + Offset(cos(minuteAngle), sin(minuteAngle)) * r * 0.8,
        Paint()
          ..strokeWidth = 4
          ..color = minuteColor
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
