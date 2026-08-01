import 'package:flutter/material.dart';

import '../app_semantic_colors.dart';
import '../app_tokens.dart';

/// Transient messages, shown as snack bars.
///
/// The app raised 17 snack bars by hand, all styled alike regardless of whether
/// they reported success or failure. These three entry points restore that
/// distinction.
///
/// Icon *plus* colour in every case, never colour alone: red/green deficiency is
/// common enough that hue cannot be the only signal — the same rule the results
/// list already follows.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) => _show(
        context,
        message,
        Icons.check_circle_outline,
        AppSemanticColors.of(context).success,
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message,
        Icons.error_outline,
        Theme.of(context).colorScheme.error,
      );

  /// Neutral acknowledgement. Styled by `snackBarTheme` alone, with no accent.
  static void info(BuildContext context, String message) =>
      _show(context, message, Icons.info_outline, null);

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color? accent,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    // A caller can outlive its Scaffold — a snack bar fired from an async
    // callback after a pop, for instance. Dropping the message beats throwing.
    if (messenger == null) return;

    final theme = Theme.of(context);
    final foreground = theme.snackBarTheme.contentTextStyle?.color ??
        theme.colorScheme.onInverseSurface;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accent ?? foreground, size: AppSize.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          // Long enough to be read at the reading speed this audience needs.
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}
