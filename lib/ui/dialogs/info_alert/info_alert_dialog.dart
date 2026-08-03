import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../common/app_tokens.dart';
import 'info_alert_dialog_model.dart';

const double _graphicSize = 60;

class InfoAlertDialog extends StackedView<InfoAlertDialogModel> {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const InfoAlertDialog({
    super.key,
    required this.request,
    required this.completer,
  });

  @override
  Widget builder(
    BuildContext context,
    InfoAlertDialogModel viewModel,
    Widget? child,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.title!, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        request.description!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 3,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: _graphicSize,
                  height: _graphicSize,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(_graphicSize / 2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⭐️', style: TextStyle(fontSize: 30)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // A real button rather than a fixed-height Container + tap
            // handler, so it meets the minimum tap target and grows when the
            // user scales text up.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completer(DialogResponse(confirmed: true)),
                child: Text(AppLocalizations.of(context)!.gotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  InfoAlertDialogModel viewModelBuilder(BuildContext context) =>
      InfoAlertDialogModel();
}
