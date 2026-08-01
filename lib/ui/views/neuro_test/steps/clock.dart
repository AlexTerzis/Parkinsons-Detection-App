import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA clock drawing, hands only: drag the two hands to read 11:10.
class ClockStep extends StatefulWidget {
  final VoidCallback onNext;
  final void Function(num score) onScored;

  const ClockStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<ClockStep> createState() => _ClockStepState();
}

enum Hand { hour, minute }

class _ClockStepState extends State<ClockStep> {
  double _hourAngle = -pi/2;
  double _minuteAngle = -pi/2;
  bool _showHint = false;
  bool _hintUsed = false;
  Hand? _activeHand;
  Timer? _completionTimer, _timeoutTimer, _hintTimer, _holdTimer;
  bool _greenState = false; // Whether both hands have stayed correct for 0.5s

  // Pre‑shifted targets (canvas 0=3 o'clock)
  static const _targetHourAngle   = ((11 + 10/60) * 30) * pi/180 - pi/2;
  static const _targetMinuteAngle = (10 * 6) * pi/180 - pi/2;
  static const _tolerance = 0.2; // ~6°

  bool _isClose(double a, double b) {
    double d = (a - b) % (2*pi);
    if (d < 0) d += 2*pi;
    if (d > pi) d = 2*pi - d;
    return d < _tolerance;
  }

  @override
  void initState() {
    super.initState();
    // Two‑minute timeout → partial scoring
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      final raw = (_isClose(_hourAngle, _targetHourAngle) ? 1.5 : 0) + (_isClose(_minuteAngle, _targetMinuteAngle) ? 1.5 : 0);
      final score = _hintUsed ? raw / 2 : raw;
      widget.onScored(score);
      widget.onNext();
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _timeoutTimer?.cancel();
    _hintTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
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
    if (_activeHand == null || _greenState) return;
    final center = size.center(Offset.zero);
    final ang = atan2(d.localPosition.dy - center.dy, d.localPosition.dx - center.dx);

    setState(() {
      if (_activeHand == Hand.hour) {
        _hourAngle = ang;
      } else {
        _minuteAngle = ang;
      }
    });
  }

  void _onPanEnd(_) {
    _activeHand = null;

    final hourIsCorrect = _isClose(_hourAngle, _targetHourAngle);
    final minuteIsCorrect = _isClose(_minuteAngle, _targetMinuteAngle);

    if (hourIsCorrect && minuteIsCorrect && !_greenState) {
      setState(() => _greenState = true);
      _timeoutTimer?.cancel();
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.stepCorrectAnswer,
      );
      _completionTimer = Timer(const Duration(seconds: 1), () {
        final score = _hintUsed ? 1.5 : 3.0;
        widget.onScored(score);
        widget.onNext();
      });
    }
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    final hourIsCorrect = _isClose(_hourAngle, _targetHourAngle);
    final minuteIsCorrect = _isClose(_minuteAngle, _targetMinuteAngle);

    return TestStepScaffold(
      title: l10n.stepTitleClock,
      instruction: l10n.stepInstructionClock,
      // The clock fills the viewport and is dragged on; a scrolling body would
      // steal the vertical drags that move the hands.
      scrollable: false,
      nextEnabled: !_greenState,
      onNext: () {
        _timeoutTimer?.cancel();
        final raw =
            (hourIsCorrect ? 1.5 : 0) + (minuteIsCorrect ? 1.5 : 0);
        final score = _hintUsed ? raw / 2 : raw;
        widget.onScored(score);
        widget.onNext();
      },
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, cons) {
                final size = cons.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _onPanStart(d, size),
                  onPanUpdate: (d) => _onPanUpdate(d, size),
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: size,
                    painter: _ClockHandsPainter(
                      hourAngle: _hourAngle,
                      minuteAngle: _minuteAngle,
                      // Green once both hands are correct, as confirmation.
                      handColor: _greenState
                          ? semantic.success
                          : theme.colorScheme.onSurface,
                      faceColor: theme.colorScheme.onSurfaceVariant,
                      hintColor: theme.colorScheme.tertiary,
                      numeralStyle: theme.textTheme.titleMedium!,
                      showHint: _showHint,
                      hintHour: _targetHourAngle,
                      hintMinute: _targetMinuteAngle,
                    ),
                  ),
                );
              },
            ),
          ),
          const AppGap.sm(),
          OutlinedButton.icon(
            onPressed: _greenState ? null : _triggerHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(l10n.stepHint),
          ),
        ],
      ),
    );
  }
}

/// Draws the clock face and its two draggable hands.
///
/// Colours and the numeral style are passed in rather than read from a theme:
/// a [CustomPainter] has no [BuildContext], so the widget resolves them and
/// hands them over.
class _ClockHandsPainter extends CustomPainter {
  _ClockHandsPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.handColor,
    required this.faceColor,
    required this.hintColor,
    required this.numeralStyle,
    required this.showHint,
    required this.hintHour,
    required this.hintMinute,
  });

  final double hourAngle, minuteAngle;
  final Color handColor, faceColor, hintColor;
  final TextStyle numeralStyle;
  final bool showHint;
  final double hintHour, hintMinute;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = min(size.width, size.height) * 0.4;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = faceColor,
    );

    for (int i = 0; i < 12; i++) {
      final a = (pi / 6) * i - pi / 2;
      final pos = Offset(
        center.dx + cos(a) * (r - 24),
        center.dy + sin(a) * (r - 24),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i == 0 ? 12 : i}',
          style: numeralStyle.copyWith(color: faceColor),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    if (showHint) {
      final paint = Paint()
        ..color = hintColor.withValues(alpha: 0.5)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        center + Offset(cos(hintHour), sin(hintHour)) * r * 0.6,
        paint,
      );
      canvas.drawLine(
        center,
        center + Offset(cos(hintMinute), sin(hintMinute)) * r * 0.8,
        paint,
      );
    }

    // Hour hand: shorter and thicker than the minute hand, as on a real face.
    canvas.drawLine(
      center,
      center + Offset(cos(hourAngle), sin(hourAngle)) * r * 0.6,
      Paint()
        ..strokeWidth = 6
        ..color = handColor
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      center,
      center + Offset(cos(minuteAngle), sin(minuteAngle)) * r * 0.8,
      Paint()
        ..strokeWidth = 4
        ..color = handColor
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockHandsPainter old) =>
      hourAngle != old.hourAngle ||
      minuteAngle != old.minuteAngle ||
      handColor != old.handColor ||
      showHint != old.showHint;
}
