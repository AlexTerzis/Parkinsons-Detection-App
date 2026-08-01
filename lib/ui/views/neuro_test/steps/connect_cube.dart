import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA visuoconstruction, dot-to-dot variant: rebuild the cube by joining
/// pairs of dots until all twelve edges are drawn and none are wrong.
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
  static const _dotSize = 32.0;

  /// The twelve edges of a cube, as sorted `a-b` index pairs.
  static const _expectedEdges = {
    '0-1', '0-2', '1-3', '2-3', //
    '4-5', '4-6', '5-7', '6-7',
    '0-4', '1-5', '2-6', '3-7',
  };

  final Set<String> _connectedPairs = {};
  final Set<String> _incorrectPairs = {};
  int? _selectedPoint;
  bool _showHint = false;
  Timer? _hintTimer;
  Timer? _timeoutTimer;
  bool _testCompleted = false;
  bool _usedHint = false;

  @override
  void initState() {
    super.initState();
    // The opening hint is free: it shows the shape being asked for. Only a
    // hint the patient asks for afterwards costs half the marks.
    _triggerHint(initial: true);
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (!_testCompleted) _finish(0);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _finish(double score) {
    if (_testCompleted) return;
    _testCompleted = true;
    _timeoutTimer?.cancel();
    widget.onScored(score);
    widget.onNext();
  }

  void _handlePointTap(int index) {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedPoint == null) {
      setState(() => _selectedPoint = index);
      return;
    }
    if (_selectedPoint == index) {
      setState(() => _selectedPoint = null);
      return;
    }

    final pair = [_selectedPoint!, index]..sort();
    final key = '${pair[0]}-${pair[1]}';
    final isExpected = _expectedEdges.contains(key);

    bool justWrong = false;

    setState(() {
      // Tapping an existing edge again removes it, which is how a wrong line
      // gets erased.
      if (_connectedPairs.contains(key)) {
        _connectedPairs.remove(key);
        _incorrectPairs.remove(key);
      } else {
        _connectedPairs.add(key);
        if (!isExpected) {
          _incorrectPairs.add(key);
          justWrong = true;
        }
      }
      _selectedPoint = null;
    });

    if (justWrong) {
      AppFeedback.error(context, l10n.stepWrongLine);
      return;
    }

    final hasAll = _expectedEdges.every(_connectedPairs.contains);
    if (!hasAll) return;

    if (_incorrectPairs.isEmpty && !_testCompleted) {
      AppFeedback.success(
        context,
        _usedHint ? l10n.stepCorrectWithHint : l10n.stepCorrectAnswer,
      );
      _testCompleted = true;
      _timeoutTimer?.cancel();
      Future.delayed(const Duration(seconds: 1), () {
        // _finish would no-op now that _testCompleted is set, so report here.
        widget.onScored(_usedHint ? 0.5 : 1.0);
        widget.onNext();
      });
    } else if (_incorrectPairs.isNotEmpty) {
      AppFeedback.info(context, l10n.stepInstructionConnectCubeAlmost);
    }
  }

  void _triggerHint({bool initial = false}) {
    setState(() {
      _showHint = true;
      if (!initial) _usedHint = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  /// The eight vertices, as two offset squares, laid out inside [size].
  ///
  /// Derived from the canvas rather than `MediaQuery.size`, so the cube stays
  /// centred in the space it actually has instead of being nudged up by a
  /// hardcoded 40px and hoping it clears the instructions.
  List<Offset> _vertices(Size size) {
    final extent = size.shortestSide * 0.62;
    final spacing = extent / 3;
    final layerGap = spacing * 0.8;
    // Biased up and left by half the layer gap so the offset front square
    // stays inside the canvas.
    final cx = size.width / 2 - layerGap / 2;
    final cy = size.height / 2 - layerGap / 2;

    return [
      Offset(cx - spacing, cy - spacing), // 0
      Offset(cx + spacing, cy - spacing), // 1
      Offset(cx - spacing, cy + spacing), // 2
      Offset(cx + spacing, cy + spacing), // 3
      Offset(cx - spacing + layerGap, cy - spacing + layerGap), // 4
      Offset(cx + spacing + layerGap, cy - spacing + layerGap), // 5
      Offset(cx - spacing + layerGap, cy + spacing + layerGap), // 6
      Offset(cx + spacing + layerGap, cy + spacing + layerGap), // 7
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    return TestStepScaffold(
      title: l10n.stepTitleCube,
      instruction: l10n.stepInstructionConnectCube,
      // Vertices are positioned absolutely against the canvas below.
      scrollable: false,
      onNext: () => _finish(0),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final points = _vertices(constraints.biggest);

                return Stack(
                  children: [
                    CustomPaint(
                      size: constraints.biggest,
                      painter: _CubeEdgePainter(
                        points: points,
                        connections: _connectedPairs,
                        incorrect: _incorrectPairs,
                        expected: _expectedEdges,
                        showHint: _showHint,
                        correctColor: semantic.success,
                        incorrectColor: theme.colorScheme.error,
                        hintColor: theme.colorScheme.tertiary,
                      ),
                    ),
                    for (final e in points.asMap().entries)
                      _buildDot(context, e.key, e.value),
                  ],
                );
              },
            ),
          ),
          const AppGap.sm(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _connectedPairs.isEmpty
                      ? null
                      : () => setState(() {
                            _connectedPairs.clear();
                            _incorrectPairs.clear();
                            _selectedPoint = null;
                            _usedHint = false;
                          }),
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.stepClear),
                ),
              ),
              const AppGap.wide(AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _triggerHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(l10n.stepHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index, Offset pos) {
    final theme = Theme.of(context);
    final selected = _selectedPoint == index;

    return Positioned(
      left: pos.dx - _dotSize / 2,
      top: pos.dy - _dotSize / 2,
      child: GestureDetector(
        onTap: () => _handlePointTap(index),
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 3 : 2,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Draws the edges the patient has joined, plus the answer while a hint shows.
class _CubeEdgePainter extends CustomPainter {
  _CubeEdgePainter({
    required this.points,
    required this.connections,
    required this.incorrect,
    required this.expected,
    required this.showHint,
    required this.correctColor,
    required this.incorrectColor,
    required this.hintColor,
  });

  final List<Offset> points;
  final Set<String> connections;
  final Set<String> incorrect;
  final Set<String> expected;
  final bool showHint;
  final Color correctColor, incorrectColor, hintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final correctPaint = Paint()
      ..color = correctColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final wrongPaint = Paint()
      ..color = incorrectColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final hintPaint = Paint()
      ..color = hintColor.withValues(alpha: 0.4)
      ..strokeWidth = 2;

    if (showHint) {
      for (final key in expected) {
        final idx = key.split('-').map(int.parse).toList();
        canvas.drawLine(points[idx[0]], points[idx[1]], hintPaint);
      }
    }

    // Drawn after the hint so the patient's own lines stay on top.
    for (final key in connections) {
      final idx = key.split('-').map(int.parse).toList();
      canvas.drawLine(
        points[idx[0]],
        points[idx[1]],
        incorrect.contains(key) ? wrongPaint : correctPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CubeEdgePainter old) =>
      old.connections.length != connections.length ||
      old.incorrect.length != incorrect.length ||
      old.showHint != showHint ||
      old.points.first != points.first;
}
