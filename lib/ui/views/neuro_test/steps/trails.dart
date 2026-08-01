import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA trail making: join 1-Α-2-Β-3-Γ-4-Δ-5-Ε in order.
///
/// The labels alternate Greek letters with digits and are the instrument's own,
/// so they stay Greek in both languages.
class TrailsStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;

  const TrailsStep({super.key, required this.onNext, required this.onScored});

  @override
  State<TrailsStep> createState() => _TrailsStepState();
}

class _TrailsStepState extends State<TrailsStep> {
  static const _sequence = ['1', 'Α', '2', 'Β', '3', 'Γ', '4', 'Δ', '5', 'Ε'];
  static const _circleSize = 60.0;

  int _currentIndex = 0;
  final List<Offset> _drawnLines = [];
  Map<String, Offset>? _anchorPoints;

  /// The canvas the anchors were laid out for. Kept so a rotation or a change
  /// in text size re-scatters them instead of leaving circles off-screen.
  Size? _laidOutFor;

  bool _testCompleted = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!_testCompleted) _finish(score: 0);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _finish({required int score}) {
    if (_testCompleted) return;
    _testCompleted = true;
    _timeoutTimer?.cancel();
    widget.onScored(score);
    widget.onNext();
  }

  /// Scatters the circles across [size], keeping them a minimum distance apart.
  ///
  /// Laid out against the real canvas rather than `MediaQuery.size` minus a
  /// hardcoded 400px bottom margin, which was a guess at the height of the
  /// instructions and button and put circles off-screen on short displays.
  void _generateAnchorPoints(Size size) {
    final rand = Random();
    const inset = _circleSize / 2 + 4;
    final minDistance = min(100.0, min(size.width, size.height) / 3);

    final usableWidth = max(1.0, size.width - 2 * inset);
    final usableHeight = max(1.0, size.height - 2 * inset);

    final used = <Offset>[];
    final result = <String, Offset>{};

    for (final label in _sequence) {
      if (result.containsKey(label)) continue;

      Offset candidate = Offset.zero;
      bool overlaps;
      int attempts = 0;

      do {
        // Give up spacing after 1000 tries rather than looping forever on a
        // canvas too small to hold ten well-separated circles.
        if (++attempts > 1000) break;
        candidate = Offset(
          rand.nextDouble() * usableWidth + inset,
          rand.nextDouble() * usableHeight + inset,
        );
        overlaps = used.any((p) => (p - candidate).distance < minDistance);
      } while (overlaps);

      used.add(candidate);
      result[label] = candidate;
    }

    _anchorPoints = result;
    _laidOutFor = size;
  }

  void _handleTap(String label) {
    if (label != _sequence[_currentIndex]) {
      AppFeedback.error(context, AppLocalizations.of(context)!.stepWrongOrder);
      return;
    }

    setState(() {
      if (_currentIndex > 0) {
        _drawnLines
          ..add(_anchorPoints![_sequence[_currentIndex - 1]]!)
          ..add(_anchorPoints![label]!);
      }
      _currentIndex++;
    });

    if (_currentIndex == _sequence.length) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _finish(score: 1),
      );
    }
  }

  Widget _buildCircle(BuildContext context, String label, Offset pos) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final visited = _sequence.indexOf(label) < _currentIndex;

    return Positioned(
      left: pos.dx - _circleSize / 2,
      top: pos.dy - _circleSize / 2,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () => _handleTap(label),
          child: Container(
            width: _circleSize,
            height: _circleSize,
            decoration: BoxDecoration(
              color: visited
                  ? semantic.successContainer
                  : theme.colorScheme.surface,
              border: Border.all(
                color: visited ? semantic.success : theme.colorScheme.outline,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                color: visited ? semantic.onSuccessContainer : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TestStepScaffold(
      title: l10n.stepTitleTrails,
      instruction: '${l10n.stepInstructionTrails}\n'
          '${l10n.stepInstructionTrailsRetry}',
      // The circles are positioned absolutely inside the canvas below.
      scrollable: false,
      onNext: () => _finish(score: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (_anchorPoints == null || _laidOutFor != size) {
            _generateAnchorPoints(size);
          }

          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _LinePainter(
                  points: _drawnLines,
                  color: theme.colorScheme.primary,
                ),
              ),
              for (final e in _anchorPoints!.entries)
                _buildCircle(context, e.key, e.value),
            ],
          );
        },
      ),
    );
  }
}

/// Draws the trail joining the circles tapped so far, as connected pairs.
class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i + 1 < points.length; i += 2) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.points.length != points.length || old.color != color;
}
