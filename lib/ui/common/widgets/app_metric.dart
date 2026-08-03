import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_section.dart';

/// A 0..1 score drawn as a labelled bar with its percentage.
///
/// Used by the results and insights tabs, which previously inlined a
/// `SizedBox(width: 150, child: LinearProgressIndicator(...))` — a fixed width
/// that clipped at large text scales.
///
/// The percentage is always rendered as text next to the bar. A bar alone
/// encodes the value in length only, which is unreadable to a screen reader and
/// hard to compare across rows.
class ScoreBar extends StatelessWidget {
  const ScoreBar({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;

  /// Score in the range 0..1. Values outside it are clamped rather than
  /// asserted: these come from model output, and a rounding artefact at 1.0000001
  /// should not crash a results screen.
  final double value;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Semantics(
      label: label,
      value: '$percent%',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
                const AppGap.wide(AppSpacing.xs),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const AppGap.xs(),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: AppSpacing.xs,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A countdown with the progress bar that goes with it.
///
/// The tap and voice tests each built this pair by hand, with different gaps
/// between the label and the bar.
class CountdownProgress extends StatelessWidget {
  const CountdownProgress({
    super.key,
    required this.label,
    required this.progress,
  });

  final String label;

  /// Elapsed fraction, 0..1. Clamped rather than asserted.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const AppGap.xs(),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: AppSpacing.xs,
          ),
        ),
      ],
    );
  }
}

/// A label/value pair on one line, for read-only detail lists.
///
/// Replaces the `Row(children: [Text(label), Spacer(), Text(value)])` shape
/// scattered through the profile and doctor tabs, which overflowed once the
/// text scaler grew.
class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const AppGap.wide(AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const AppGap.wide(AppSpacing.md),
          // Flexible rather than a fixed width: long values wrap instead of
          // overflowing when the user raises the text size.
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
