import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'tapping_task_step.dart';

/// FAB sensitivity to interference: tap twice on 1, once on 2.
class ConflictingInstructionsStep extends StatelessWidget {
  const ConflictingInstructionsStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  final VoidCallback onNext;
  final void Function(int score) onScored;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TappingTaskStep(
      onNext: onNext,
      onScored: onScored,
      title: l10n.stepTitleConflicting,
      instructions: l10n.fabConflictingInstructions,
      rules: l10n.fabConflictingRules,
      practiceIntro: l10n.fabConflictingPracticeIntro,
      testIntro: l10n.fabConflictingTestIntro,
      // The conflict itself: the response is the opposite of the stimulus.
      expectedTaps: (stimulus) => stimulus == 1 ? 2 : 1,
      wrongMessage: (l10n, expected, actual) => expected == 2
          ? l10n.fabExpectedTapsTwice(actual)
          : l10n.fabExpectedTapsOnce(actual),
      streakMessage: (l10n) => l10n.fabResultStreakStimulus,
    );
  }
}
