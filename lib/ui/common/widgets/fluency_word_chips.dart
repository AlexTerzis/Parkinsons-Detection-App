import 'package:flutter/material.dart';

import '../app_semantic_colors.dart';
import '../app_tokens.dart';

/// Heard words as chips. Words that count are marked with an icon as well as
/// a tint, so the cue is not colour alone; words still being recognised are
/// shown faded until the recogniser confirms them.
class FluencyWordChips extends StatelessWidget {
  const FluencyWordChips({
    super.key,
    required this.words,
    required this.pending,
    required this.isValid,
  });

  final List<String> words;
  final List<String> pending;
  final bool Function(String word) isValid;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (final w in words)
          Chip(
            label: Text(w),
            avatar: isValid(w)
                ? Icon(Icons.check, color: semantic.success)
                : null,
            backgroundColor: isValid(w) ? semantic.successContainer : null,
          ),
        for (final w in pending)
          Opacity(opacity: 0.5, child: Chip(label: Text(w))),
      ],
    );
  }
}
