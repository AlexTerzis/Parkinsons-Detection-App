import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// The timed tapping paradigm shared by the FAB's go/no-go and conflicting
/// instructions tasks.
///
/// The two were separate ~380-line files that differed only in the rule
/// mapping a stimulus to the expected number of taps, and in the wording of
/// the practice feedback. Everything else — the four phases, the identical
/// stimulus sequences, the 400ms blink, the 2200/1500ms exposures, the
/// consecutive-match check and the 0-3 scoring — was duplicated verbatim.
class TappingTaskStep extends StatefulWidget {
  const TappingTaskStep({
    super.key,
    required this.onNext,
    required this.onScored,
    required this.title,
    required this.instructions,
    required this.rules,
    required this.practiceIntro,
    required this.testIntro,
    required this.expectedTaps,
    required this.wrongMessage,
    required this.streakMessage,
  });

  final VoidCallback onNext;
  final void Function(int score) onScored;

  final String title;
  final String instructions;

  /// The rule reminder, kept on screen throughout the timed phases.
  final String rules;

  final String practiceIntro;
  final String testIntro;

  /// How many taps the stimulus calls for. This is the whole difference
  /// between the two tasks: go/no-go answers 1→1 and 2→0, conflicting
  /// instructions answers 1→2 and 2→1.
  final int Function(int stimulus) expectedTaps;

  /// Practice feedback for a wrong trial, given what was expected and what the
  /// patient actually did.
  final String Function(AppLocalizations l10n, int expected, int actual)
      wrongMessage;

  /// Explanation when the patient simply echoed the stimulus throughout, which
  /// scores zero however few "errors" it produces.
  final String Function(AppLocalizations l10n) streakMessage;

  @override
  State<TappingTaskStep> createState() => _TappingTaskStepState();
}

class _TappingTaskStepState extends State<TappingTaskStep> {
  static const List<int> _trainingSequence = [1, 1, 1, 2, 2, 2];
  static const List<int> _testSequence = [1, 1, 2, 1, 2, 2, 2, 1, 1, 2];

  int _index = -1;
  int _current = 0;
  int _tapCount = 0;
  int _errors = 0;
  int _sameStreak = 0;
  bool _testDone = false;
  int _phase = 0; // 0 = instructions, 1 = practice, 2 = main test
  Timer? _timer;
  bool _showNumber = true;
  bool _waitingToStart = false;

  // Practice feedback, kept as what happened rather than as a formatted string
  // and a Color, so build() can localise and theme it.
  bool? _lastCorrect;
  int _lastExpected = 0;
  int _lastActual = 0;

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
        _lastCorrect = null;
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
        _lastCorrect = null;
      });
    } else {
      _finish();
    }
  }

  void _startPhase() {
    setState(() {
      _waitingToStart = false;
      _index = -1;
      _tapCount = 0;
      _testDone = false;
      _lastCorrect = null;
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

    bool? correct;
    int expected = 0;
    final actual = _tapCount;

    if (_index >= 0 && !_testDone) {
      final sequence = _phase == 1 ? _trainingSequence : _testSequence;
      final stim = sequence[_index];
      expected = widget.expectedTaps(stim);

      if (_phase == 1) {
        correct = _tapCount == expected;
      } else {
        // Main test: score silently, so feedback cannot cue the patient.
        if (_tapCount != expected) _errors++;
        if (_tapCount == stim) {
          _sameStreak++;
        } else {
          _sameStreak = 0;
        }
      }
    }

    setState(() {
      _showNumber = false;
      _lastCorrect = _phase == 1 ? correct : null;
      _lastExpected = expected;
      _lastActual = actual;
      _index += 1;

      final length = _phase == 1
          ? _trainingSequence.length
          : _testSequence.length;
      if (_index >= length) {
        _testDone = true;
        _current = 0;
      } else {
        _current =
            _phase == 1 ? _trainingSequence[_index] : _testSequence[_index];
        _tapCount = 0;
      }
    });

    // Blank for 400ms, then show the next stimulus. The practice round holds
    // each one longer, to leave room for the feedback to be read.
    if (!_testDone) {
      _timer = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _showNumber = true);
        final showDuration = _phase == 1 ? 2200 : 1500;
        _timer = Timer(Duration(milliseconds: showDuration), _next);
      });
    }
  }

  void _finish() {
    _timer?.cancel();
    widget.onScored(_phase == 2 ? _score : 0);
    widget.onNext();
  }

  /// Echoing the stimulus throughout scores zero regardless of the error count:
  /// it means the rule was never applied.
  int get _score {
    if (_sameStreak >= 4) return 0;
    if (_errors == 0) return 3;
    if (_errors <= 2) return 2;
    return 1;
  }

  String _explanation(AppLocalizations l10n) {
    if (_sameStreak >= 4) return widget.streakMessage(l10n);
    if (_errors == 0) return l10n.fabGoNoGoResultPerfect;
    if (_errors <= 2) return l10n.fabGoNoGoResultFew;
    return l10n.fabGoNoGoResultMany;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    if (_phase == 0) {
      return TestStepScaffold(
        title: widget.title,
        instruction: widget.instructions,
        nextLabel: l10n.stepStart,
        onNext: _nextPhase,
        child: Center(child: _rulesCard(context)),
      );
    }

    if (_waitingToStart) {
      return TestStepScaffold(
        title: widget.title,
        instruction: _phase == 1 ? widget.practiceIntro : widget.testIntro,
        nextLabel: l10n.stepStart,
        onNext: _startPhase,
        child: Center(child: _rulesCard(context)),
      );
    }

    if (_phase == 2 && _testDone) {
      return TestStepScaffold(
        title: l10n.stepResults,
        onNext: _finish,
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.fabScoreValue('$_score'),
                  style: theme.textTheme.headlineMedium,
                ),
                const AppGap.sm(),
                Text(
                  _explanation(l10n),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final correct = _lastCorrect;

    return TestStepScaffold(
      title: widget.title,
      // No scrolling: the stimulus must hold a fixed position, and the screen
      // is reacted to rather than read.
      scrollable: false,
      onNext: _nextPhase,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rulesCard(context),
          const AppGap.lg(),
          // Fixed height so the tap target does not shift as the stimulus
          // blinks between trials.
          SizedBox(
            height: 96,
            child: Center(
              child: Text(
                _showNumber && !_testDone ? '$_current' : '',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const AppGap.lg(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _testDone ? null : _recordAnswer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(110),
                textStyle: theme.textTheme.displaySmall,
              ),
              child: Text(l10n.fabTap),
            ),
          ),
          const AppGap.lg(),
          // Practice only, with reserved height for the same reason.
          SizedBox(
            height: 72,
            child: correct == null
                ? null
                : Text(
                    correct
                        ? l10n.stepCorrectAnswer
                        : widget.wrongMessage(l10n, _lastExpected, _lastActual),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: correct ? semantic.success : theme.colorScheme.error,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// The rules, on screen throughout so they never have to be recalled.
  Widget _rulesCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        widget.rules,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
