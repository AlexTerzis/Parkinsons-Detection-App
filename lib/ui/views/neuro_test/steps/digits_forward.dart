import 'package:flutter/material.dart';

import 'digit_span_step.dart';

/// MoCA digit span, forward: repeat 2-1-8-5-4 in the order given.
class DigitsForwardStep extends StatelessWidget {
  const DigitsForwardStep({
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
      sequence: '2 1 8 5 4',
      expectedAnswer: '21854',
      memoriseInstruction: (l10n) =>
          '${l10n.stepInstructionDigitsMemorise}\n'
          '${l10n.stepInstructionDigitsForwardSoon}',
      recallInstruction: (l10n) => l10n.stepInstructionDigitsForward,
    );
  }
}
