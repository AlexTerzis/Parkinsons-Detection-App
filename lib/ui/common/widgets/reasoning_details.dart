import 'package:flutter/material.dart';

import 'widgets.dart';

/// The full rAIson+ explanation folded under "How this was reached", for
/// the patient's screens. [lines] are already in plain words.
class ReasoningDetails extends StatelessWidget {
  const ReasoningDetails({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final greek = Localizations.localeOf(context).languageCode == 'el';

    return ExpansionTile(
      title: Text(
        greek ? 'Πώς προέκυψε' : 'How this was reached',
        style: theme.textTheme.bodyMedium,
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.xxs,
            ),
            child: Text('• $line', style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
