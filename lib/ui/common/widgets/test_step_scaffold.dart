import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../app_tokens.dart';
import 'app_scaffold.dart';
import 'app_section.dart';

/// Supplies "step N of M" to every [TestStepScaffold] beneath it.
///
/// An inherited scope rather than a constructor argument because the step
/// widgets are built eagerly, in a list, by the battery's view model — they do
/// not know their own position, and threading an index through all twenty
/// constructors would couple each step to its place in the running order.
class TestStepProgress extends InheritedWidget {
  const TestStepProgress({
    super.key,
    required this.index,
    required this.count,
    required super.child,
  });

  /// 1-based position within the battery.
  final int index;
  final int count;

  static TestStepProgress? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TestStepProgress>();

  @override
  bool updateShouldNotify(TestStepProgress oldWidget) =>
      index != oldWidget.index || count != oldWidget.count;
}

/// The frame every step of a multi-step assessment shares.
///
/// The 20 neuro and FAB step files each hand-rolled this: an [AppBar], an
/// instruction paragraph, the interactive content, and a "Next" button dropped
/// into a [Stack] via [Positioned]. Several nested two to four [Scaffold]s
/// while doing it.
///
/// Three things this fixes beyond the duplication:
///
/// * The Next button sits in a pinned bar rather than a `Positioned` corner, so
///   it cannot drift under the keyboard or off screen at large text scales.
/// * Progress is visible. A patient part-way through a fifteen-step battery had
///   no way to tell how much was left.
/// * The back button is suppressed. Steps are scored on first response; letting
///   someone pop back mid-battery corrupts the score, which is why the original
///   files each carried their own `automaticallyImplyLeading: false`.
class TestStepScaffold extends StatelessWidget {
  const TestStepScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onNext,
    this.instruction,
    this.nextEnabled = true,
    this.nextLabel,
    this.stepIndex,
    this.stepCount,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final String title;

  /// What the patient is being asked to do. Rendered as the one prominent
  /// paragraph on the screen, above the interactive content.
  final String? instruction;

  final Widget child;

  /// Advances the battery. Null disables the button, for steps that must be
  /// answered before moving on.
  final VoidCallback? onNext;

  final bool nextEnabled;

  /// Defaults to the localized "Next".
  final String? nextLabel;

  /// 1-based position within the battery. Defaults to the enclosing
  /// [TestStepProgress], which is how the neuro and FAB batteries supply it;
  /// set explicitly only for a step shown outside a battery.
  final int? stepIndex;
  final int? stepCount;

  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final scope = TestStepProgress.maybeOf(context);
    final index = stepIndex ?? scope?.index;
    final count = stepCount ?? scope?.count;
    final showProgress = index != null && count != null && count > 0;

    return AppScaffold(
      title: title,
      showBackButton: false,
      scrollable: scrollable,
      padding: padding,
      actions: showProgress
          ? [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Text(
                    l10n.stepOfSteps(index, count),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ]
          : null,
      bottomAction: PrimaryAction(
        label: nextLabel ?? l10n.next,
        icon: Icons.arrow_forward,
        onPressed: nextEnabled ? onNext : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showProgress) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: index / count,
                minHeight: 6,
              ),
            ),
            const AppGap.md(),
          ],
          if (instruction != null) ...[
            Text(
              instruction!,
              style: theme.textTheme.bodyLarge,
            ),
            const AppGap.lg(),
          ],
          // Expanded rather than a bare child: AppScaffold wraps a scrollable
          // body in IntrinsicHeight over a min-height box, so the content gets
          // the full viewport when it fits and scrolls when it does not.
          Expanded(child: child),
        ],
      ),
    );
  }
}
