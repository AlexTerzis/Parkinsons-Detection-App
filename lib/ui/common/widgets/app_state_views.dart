import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_section.dart';

/// Centred progress indicator with an optional caption.
///
/// Replaces the bare `Center(child: CircularProgressIndicator())` that appeared
/// in ten files. The caption matters more here than in most apps: several of
/// these waits are multi-second TFLite or network calls, and an unexplained
/// spinner reads as a hang.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const AppGap.md(),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when a list or screen has nothing to display yet.
///
/// Always offer [action] where the user can plausibly do something about the
/// emptiness — "no results yet" with a button to start a test is guidance; the
/// same sentence alone is a dead end.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: AppOpacity.strong),
            ),
            const AppGap.md(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const AppGap.xs(),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const AppGap.lg(),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Failure state with an optional retry.
///
/// Uses the error colour on the icon only, never on the body copy: the message
/// is often long, and `colorScheme.error` is tuned for accents rather than
/// paragraphs.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const AppGap.md(),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const AppGap.xs(),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const AppGap.lg(),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? MaterialLocalizations.of(context)
                    .refreshIndicatorSemanticLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
