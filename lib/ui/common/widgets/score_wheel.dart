import 'package:flutter/material.dart';

import '../app_semantic_colors.dart';
import '../app_tokens.dart';
import 'app_section.dart';

/// A screening score as a dial: `24` over `of 30`, with the ring filled to
/// match and coloured by how the result reads.
///
/// For MoCA and FAB the ring shows **performance**, not concern — a fuller ring
/// is a better result — because that is the direction the instruments are
/// scored in and the number in the middle is the one a clinician quotes. The
/// colour comes from the band, so a nearly-full ring cannot be green while the
/// score sits below the cut-off.
///
/// The label under the number is never omitted. A ring on its own says
/// "roughly this much" and a clinician needs "24 of 30".
class ScoreWheel extends StatelessWidget {
  const ScoreWheel({
    super.key,
    required this.score,
    required this.outOf,
    required this.label,
    required this.color,
    this.caption,
    this.size = 104,
  });

  /// The raw score, as the instrument counts it.
  final int score;

  /// The instrument's maximum.
  final int outOf;

  /// What the instrument is called.
  final String label;

  /// Band colour — resolved by the caller, which knows the test type.
  final Color color;

  /// An optional line under the dial, e.g. a repeat warning.
  final String? caption;

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guarded: a malformed document must not produce a NaN sweep, which
    // throws inside the painter rather than merely looking wrong.
    final fraction = outOf <= 0 ? 0.0 : (score / outOf).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const AppGap.xs(),
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clamped so the dial keeps its proportions when the user scales
              // text up; the number inside is what grows instead.
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  Text(
                    'of $outOf',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (caption != null) ...[
          const AppGap.xxs(),
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.of(context).warning,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A horizontal bar for a 0-1 concern value, with its own label and figure.
///
/// Used where a dial would be wrong: the app's own sensor measures have no
/// instrument maximum to count against, only a proportion.
class ConcernBar extends StatelessWidget {
  const ConcernBar({
    super.key,
    required this.label,
    required this.concern,
    required this.color,
    this.trailing,
  });

  final String label;
  final double concern;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              '${(concern * 100).round()}%',
              style: theme.textTheme.titleSmall,
            ),
            if (trailing != null) ...[
              const AppGap.wide(AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
        const AppGap.xxs(),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: concern.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
