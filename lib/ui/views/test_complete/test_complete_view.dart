import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/test_score_interpretation.dart';
import '../../../models/test_type.dart';
import '../../../services/authentication_service.dart';
import '../../common/widgets/widgets.dart';
import '../patience_view/test_catalogue.dart';

/// Shown when any test finishes.
///
/// Every test used to end by either popping straight back to the list or, in
/// four cases, doing nothing at all — so a patient could complete a fifteen-step
/// battery and be given no indication of how they did or whether it saved.
///
/// One screen for all of them, so the ending is consistent and there is exactly
/// one place where a score is turned into words.
class TestCompleteView extends StatelessWidget {
  const TestCompleteView({
    super.key,
    required this.type,
    required this.concern,
    this.detail,
    this.saved = true,
  });

  final TestType type;

  /// 0-1 where higher is more concerning, as stored on the result.
  final double concern;

  /// Optional raw form, e.g. "24 / 30", shown beside the percentage where the
  /// underlying scale is more meaningful to a patient than a percentage.
  final String? detail;

  /// False when the result could not be written. The patient is told rather
  /// than left to assume it was kept.
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    final band = TestScoreInterpretation.bandOfConcern(type, concern);
    final direction = TestScoreInterpretation.directionOf(type);

    final Color bandColor = switch (band) {
      ScoreBand.reassuring => semantic.success,
      ScoreBand.borderline => semantic.warning,
      ScoreBand.notable => theme.colorScheme.error,
    };

    final bool isGuest = locator<AuthenticationService>().isGuest;

    return PopScope(
      // Back must land where Done lands, not on the test that was just
      // finished, which would restart it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AppScaffold(
        title: l10n.testCompleteTitle,
        showBackButton: false,
        bottomAction: PrimaryAction(
          label: l10n.testCompleteDone,
          icon: Icons.check,
          onPressed: _close,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppGap.md(),
            Icon(
              // Icon as well as colour: red/green deficiency is common, and
              // this is the screen's main signal.
              switch (band) {
                ScoreBand.reassuring => Icons.check_circle_outline,
                ScoreBand.borderline => Icons.info_outline,
                ScoreBand.notable => Icons.flag_outlined,
              },
              size: 56,
              color: bandColor,
            ),
            const AppGap.md(),
            Text(
              type.label(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const AppGap.xs(),
            Text(
              saved ? l10n.testCompleteSaved : l10n.testCompleteNotSaved,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: saved
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            const AppGap.lg(),

            // The bar always fills toward the worrying end, whichever way the
            // underlying score runs, so a full bar never means two things.
            ScoreBar(
              label: detail == null
                  ? l10n.testCompleteScore
                  : '${l10n.testCompleteScore}  ·  $detail',
              value: concern,
              color: bandColor,
            ),
            const AppGap.lg(),

            AppCard(
              child: Text(
                switch ((direction, band)) {
                  (ScoreDirection.higherIsWorse, ScoreBand.reassuring) =>
                    l10n.bandReassuringWorse,
                  (ScoreDirection.higherIsWorse, ScoreBand.borderline) =>
                    l10n.bandBorderlineWorse,
                  (ScoreDirection.higherIsWorse, ScoreBand.notable) =>
                    l10n.bandNotableWorse,
                  (ScoreDirection.higherIsBetter, ScoreBand.reassuring) =>
                    l10n.bandReassuringBetter,
                  (ScoreDirection.higherIsBetter, ScoreBand.borderline) =>
                    l10n.bandBorderlineBetter,
                  (ScoreDirection.higherIsBetter, ScoreBand.notable) =>
                    l10n.bandNotableBetter,
                },
                style: theme.textTheme.bodyLarge,
              ),
            ),

            if (isGuest) ...[
              const AppGap.md(),
              _GuestKeepCard(),
            ],

            const AppGap.lg(),
            Text(
              l10n.screeningDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const AppGap.md(),
          ],
        ),
      ),
    );
  }

  void _close() => locator<NavigationService>().back();
}

/// Guest-only prompt, shown at the moment the patient has just produced
/// something worth keeping.
class _GuestKeepCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_border, color: cs.onSecondaryContainer),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.guestKeepResultsTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: cs.onSecondaryContainer),
                ),
              ),
            ],
          ),
          const AppGap.xs(),
          Text(
            l10n.guestKeepResultsBody,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Replaces the finished test with its result screen.
///
/// `pushReplacement` rather than push: the test is over, and leaving it beneath
/// means a back gesture would drop the patient into a completed battery.
///
/// Falls back to a plain pop if the navigator is somehow unavailable, so a
/// patient can never be stranded on a finished test.
Future<void> showTestComplete({
  required TestType type,
  required double concern,
  String? detail,
  bool saved = true,
}) async {
  final navigatorState = StackedService.navigatorKey?.currentState;

  if (navigatorState == null) {
    locator<NavigationService>().back();
    return;
  }

  await navigatorState.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => TestCompleteView(
        type: type,
        concern: concern,
        detail: detail,
        saved: saved,
      ),
    ),
  );
}
