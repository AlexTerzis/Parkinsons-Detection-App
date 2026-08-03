import 'package:flutter/material.dart';

import 'package:parkinsondetetion/l10n/app_localizations.dart';

/// A small "what am I looking at?" affordance for a chart or section.
///
/// Every number this app shows is a model output with caveats attached, and a
/// screen full of unexplained percentages is the failure mode of a screening
/// tool. The explanation lives one tap away rather than inline so the screen
/// stays readable for someone who already knows.
class AppInfoButton extends StatelessWidget {
  const AppInfoButton({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      // Named for a screen reader, which otherwise announces only "button".
      tooltip: title,
      onPressed: () => showAppInfoDialog(context, title: title, body: body),
    );
  }
}

/// Shows an explanatory dialog. Scrolls, because these run long at a large
/// text scale and this app ships one.
Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          body,
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}
