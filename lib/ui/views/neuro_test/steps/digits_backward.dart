import 'package:flutter/material.dart';

import 'digit_span_step.dart';

/// MoCA digit span, backward: repeat 7-4-2 in reverse, so the answer is 2-4-7.
class DigitsBackwardStep extends StatelessWidget {
  const DigitsBackwardStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  final VoidCallback onNext;
  final void Function(double score) onScored;

  @override
  Widget build(BuildContext context) {
    return DigitSpanStep(
      onNext: onNext,
      onScored: onScored,
      sequence: '7 4 2',
      expectedAnswer: '247',
      memoriseInstruction: (l10n) =>
          '${l10n.stepInstructionDigitsMemorise}\n'
          '${l10n.stepInstructionDigitsBackwardSoon}',
      recallInstruction: (l10n) => l10n.stepInstructionDigitsBackward,
    );
  }
}
