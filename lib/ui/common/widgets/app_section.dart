import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A gap on the [AppSpacing] scale.
///
/// Exists so views never spell a spacing number out loud. `const AppGap.md()`
/// reads no worse than `SizedBox(height: 16)` and cannot drift off the scale.
///
/// Vertical by default, because that is what the app overwhelmingly needs
/// (196 `SizedBox(height:)` against a handful of widths). Direction is an
/// explicit choice rather than inferred from the enclosing [Flex]: inference
/// would need an ancestor walk on every build, and a gap that silently changes
/// axis when a [Column] becomes a [Row] is worse than one that stays wrong
/// visibly.
class AppGap extends StatelessWidget {
  const AppGap(this.size, {super.key}) : axis = Axis.vertical;

  const AppGap.xxs({super.key})
      : size = AppSpacing.xxs,
        axis = Axis.vertical;
  const AppGap.xs({super.key})
      : size = AppSpacing.xs,
        axis = Axis.vertical;
  const AppGap.sm({super.key})
      : size = AppSpacing.sm,
        axis = Axis.vertical;
  const AppGap.md({super.key})
      : size = AppSpacing.md,
        axis = Axis.vertical;
  const AppGap.lg({super.key})
      : size = AppSpacing.lg,
        axis = Axis.vertical;
  const AppGap.xl({super.key})
      : size = AppSpacing.xl,
        axis = Axis.vertical;
  const AppGap.xxl({super.key})
      : size = AppSpacing.xxl,
        axis = Axis.vertical;

  /// A horizontal gap, for use inside a [Row].
  const AppGap.wide(this.size, {super.key}) : axis = Axis.horizontal;

  final double size;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.horizontal ? size : null,
      height: axis == Axis.vertical ? size : null,
    );
  }
}

/// A titled section heading with an optional trailing action.
///
/// The app had accumulated `Text(..., style: textTheme.titleLarge)` followed by
/// a hand-picked gap in a dozen places, each with a slightly different gap.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;

  /// Trailing control, typically a [TextButton] or [IconButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...[
          const AppGap.xxs(),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: action == null
          ? text
          : LayoutBuilder(
              builder: (context, constraints) {
                // A button takes its intrinsic width, and at a large text
                // scale that can be most of the row — leaving the title a
                // sliver to wrap in, which then runs off the bottom of the
                // screen. Past a third of the width, stack instead.
                final actionWidth = _estimatedActionWidth(context);
                final crowded = actionWidth > constraints.maxWidth / 3;

                if (crowded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      const AppGap.xs(),
                      Align(alignment: Alignment.centerLeft, child: action!),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: text),
                    const AppGap.wide(AppSpacing.xs),
                    action!,
                  ],
                );
              },
            ),
    );
  }

  /// Estimates the action's width from the text scaler.
  ///
  /// A real intrinsic measurement would need the action laid out first, which
  /// is what we are trying to avoid; the scaler is what actually drives the
  /// growth, so it is a good enough proxy for "is this about to crowd out the
  /// title".
  double _estimatedActionWidth(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    // ~120dp is a typical text button; it grows roughly with the scaler.
    return 120 * scale;
  }
}
