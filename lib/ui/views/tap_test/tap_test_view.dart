import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/widgets.dart';
import 'tap_test_viewmodel.dart';

/// Finger-tapping speed test.
class TapTestView extends StackedView<TapTestViewModel> {
  const TapTestView({super.key});

  @override
  Widget builder(
    BuildContext context,
    TapTestViewModel viewModel,
    Widget? child,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.tapTest,
      // The tap target must stay put; a scrolling body would move it under the
      // finger mid-test.
      scrollable: false,
      bottomAction: viewModel.isTesting
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: viewModel.stopTest,
                icon: const Icon(Icons.stop),
                label: Text(l10n.stop),
              ),
            )
          : PrimaryAction(
              label: l10n.startTest,
              icon: Icons.play_arrow,
              onPressed: () => viewModel.startTest(l10n),
            ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            viewModel.statusText(l10n),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (viewModel.isTesting) ...[
            const AppGap.lg(),
            CountdownProgress(
              label: l10n.timeLeft(viewModel.secondsLeft),
              progress: viewModel.progress,
            ),
          ],
          const AppGap.xl(),
          Center(
            child: GestureDetector(
              onTapDown: (_) => viewModel.onTapDown(),
              onTapUp: (_) => viewModel.onTapUp(),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Dimmed until the test is running, so it is obvious the pad
                  // is not yet live.
                  color: viewModel.isTesting
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    l10n.tap,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: viewModel.isTesting
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (viewModel.resultHand1.isNotEmpty ||
              viewModel.resultHand2.isNotEmpty) ...[
            const AppGap.xl(),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.resultHand1.isNotEmpty)
                    Text(viewModel.resultHand1,
                        style: theme.textTheme.bodyLarge),
                  if (viewModel.resultHand2.isNotEmpty)
                    Text(viewModel.resultHand2,
                        style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  TapTestViewModel viewModelBuilder(BuildContext context) => TapTestViewModel();

  @override
  void onViewModelReady(TapTestViewModel viewModel) {
    viewModel.loadModel();
    super.onViewModelReady(viewModel);
  }
}
