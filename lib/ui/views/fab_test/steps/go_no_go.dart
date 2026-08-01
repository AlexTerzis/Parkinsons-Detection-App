import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'tapping_task_step.dart';

/// FAB inhibitory control: tap once on 1, withhold entirely on 2.
class GoNoGoStep extends StatelessWidget {
  const GoNoGoStep({
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
      title: l10n.stepTitleGoNoGo,
      instructions: l10n.fabGoNoGoInstructions,
      rules: l10n.fabGoNoGoRules,
      practiceIntro: l10n.fabGoNoGoPracticeIntro,
      testIntro: l10n.fabGoNoGoTestIntro,
      expectedTaps: (stimulus) => stimulus == 1 ? 1 : 0,
      wrongMessage: (l10n, expected, actual) {
        // Withholding is the harder instruction, so it keeps its own wording
        // rather than being folded into "you should have tapped 0 times".
        if (expected == 0) return l10n.fabGoNoGoShouldNotTap(actual);
        if (actual == 0) return l10n.fabGoNoGoMissed;
        return l10n.fabGoNoGoTooMany(actual);
      },
      streakMessage: (l10n) => l10n.fabGoNoGoResultStreak,
    );
  }
}
