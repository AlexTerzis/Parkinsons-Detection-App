import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../models/camera_task_protocol.dart';
import '../../../services/scoring/camera_test_report.dart';
import '../../common/widgets/widgets.dart';
import 'camera_test_viewmodel.dart';

/// What the patient sees after the camera assessment.
///
/// Built around two things: what was measured, and how well it was recorded.
/// The combined heuristic score is deliberately absent — it is an uncalibrated
/// research output, and putting a single number at the top of this screen would
/// give it a standing it has not earned, whatever the wording around it.
///
/// Every number here is a measurement of movement, stated in its own units and
/// left uninterpreted. There is no reference range, no colour coding against a
/// threshold, and no statement that any value is normal or abnormal — this app
/// has no validated basis for any of those, and inventing one would be the
/// diagnosis-shaped claim this whole screen exists to avoid.
class CameraResultsView extends StatelessWidget {
  const CameraResultsView({super.key, required this.viewModel});

  final CameraTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final report = viewModel.report;

    return AppScaffold(
      title: l10n.cameraResultsTitle,
      showBackButton: false,
      bottomAction: PrimaryAction(
        label: l10n.cameraResultsNext,
        icon: Icons.arrow_forward,
        onPressed: viewModel.finishFromResults,
      ),
      body: report == null || !report.hasAnyMeasurement
          ? _nothingMeasured(context, l10n, theme)
          : _results(context, l10n, theme, report),
    );
  }

  Widget _nothingMeasured(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant),
              const AppGap.wide(AppSpacing.sm),
              Expanded(child: Text(l10n.cameraResultsNothing)),
            ],
          ),
        ),
        const AppGap.md(),
        OutlinedButton.icon(
          onPressed: viewModel.repeatTest,
          icon: const Icon(Icons.replay),
          label: Text(l10n.cameraResultsRepeat),
        ),
      ],
    );
  }

  Widget _results(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    CameraTestReport report,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cameraResultsIntro,
                  style: theme.textTheme.bodyMedium),
              const AppGap.sm(),
              Row(
                children: [
                  Icon(
                    viewModel.resultSaved
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const AppGap.wide(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      viewModel.resultSaved
                          ? l10n.cameraResultsSaved
                          : l10n.cameraResultsNotSaved,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const AppGap.md(),
        _qualitySection(context, l10n, theme, report),
        const AppGap.md(),
        for (final type in const <CameraTaskType>[
          CameraTaskType.fingerTap,
          CameraTaskType.openClose,
          CameraTaskType.pronationSupination,
          CameraTaskType.rest,
        ]) ...[
          _taskSection(context, l10n, theme, report, type),
          const AppGap.md(),
        ],
        _comparisonSection(context, l10n, theme, report),
        const AppGap.md(),
        _overallMovementSection(context, l10n, theme),
        const AppGap.md(),
        _diagnosticsSection(context, l10n, theme, report),
        const AppGap.md(),
        OutlinedButton.icon(
          onPressed: viewModel.repeatTest,
          icon: const Icon(Icons.replay),
          label: Text(l10n.cameraResultsRepeat),
        ),
      ],
    );
  }

  // --- Always-available measurements ---

  /// The whole-recording measures, per hand.
  ///
  /// These come from `HandMetrics` over the raw positions and cannot fail: they
  /// are variances of frame-to-frame displacement, so they exist whenever any
  /// frames were captured. They are cruder than the per-task features above —
  /// they do not know about elapsed time or task boundaries — but they are the
  /// numbers this test produced before the per-task analysis was added, and
  /// they should never have stopped being shown when it cannot report.
  Widget _overallMovementSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final data = viewModel.lastMetrics;
    if (data.isEmpty) return const SizedBox.shrink();

    double? read(String key) => (data[key] as num?)?.toDouble();

    Widget row(String label, String leftKey, String rightKey) {
      final left = read(leftKey);
      final right = read(rightKey);
      if (left == null && right == null) return const SizedBox.shrink();
      return _metric(
        context,
        label,
        '${left?.toStringAsFixed(3) ?? '—'} · '
        '${right?.toStringAsFixed(3) ?? '—'}',
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cameraOverallMovement, style: theme.textTheme.titleMedium),
          const AppGap.xs(),
          Text(
            '${l10n.cameraHandLeft} · ${l10n.cameraHandRight}',
            style: theme.textTheme.labelMedium,
          ),
          const AppGap.sm(),
          row(l10n.cameraMetricSpeedVariation, 'speed_variance_left',
              'speed_variance_right'),
          row(l10n.cameraMetricAccelVariation, 'accel_variance_left',
              'accel_variance_right'),
          row(l10n.cameraMetricJerkVariation, 'jerk_variance_left',
              'jerk_variance_right'),
          row(l10n.cameraMetricFingerSpread, 'finger_spread_left',
              'finger_spread_right'),
          row(l10n.cameraMetricTremorLevel, 'rest_tremor_left',
              'rest_tremor_right'),
          if (read('asymmetry') != null)
            _metric(context, l10n.cameraMetricHandDifference,
                read('asymmetry')!.toStringAsFixed(3)),
          const AppGap.sm(),
          Text(l10n.cameraOverallMovementNote,
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// The numbers needed to work out why a measurement is missing.
  ///
  /// Collapsed by default — it is not for the patient. It exists because
  /// diagnosing "the results are empty" from a phone otherwise means guessing,
  /// and guessing is what produced several rounds of wrong fixes.
  Widget _diagnosticsSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    CameraTestReport report,
  ) {
    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(l10n.cameraDiagnosticsTitle,
            style: theme.textTheme.titleMedium),
        children: [
          if (viewModel.reportError != null) ...[
            _metric(context, l10n.cameraDiagErrorLabel, viewModel.reportError!),
            const AppGap.sm(),
          ],
          for (final hand in report.hands)
            for (final task in hand.tasks) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(task.taskId, style: theme.textTheme.labelLarge),
              ),
              _metric(
                context,
                l10n.cameraDiagFramesLabel,
                '${task.quality.confidence.toStringAsFixed(2)} conf · '
                '${task.valid ? 'valid' : 'invalid'}',
              ),
              _metric(context, l10n.cameraDiagCyclesLabel,
                  '${task.cycles?.cycleCount ?? 0}'),
              _metric(
                context,
                l10n.cameraDiagFpsLabel,
                task.cycles?.fps.toStringAsFixed(1) ?? '—',
              ),
              if (task.quality.failures.isNotEmpty)
                _metric(
                  context,
                  l10n.cameraDiagSignalLabel,
                  task.quality.failures
                      .map((f) =>
                          '${f.check.name} ${f.measured.toStringAsFixed(2)}'
                          '/${f.required_.toStringAsFixed(2)}')
                      .join(', '),
                ),
              const AppGap.sm(),
            ],
        ],
      ),
    );
  }

  // --- Recording quality ---

  Widget _qualitySection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    CameraTestReport report,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cameraResultsQuality,
              style: theme.textTheme.titleMedium),
          const AppGap.sm(),
          _percentRow(
            context,
            l10n.cameraResultsOverallConfidence,
            report.confidence,
          ),
          for (final hand in report.hands)
            _percentRow(
              context,
              hand.hand == 'Left' ? l10n.cameraHandLeft : l10n.cameraHandRight,
              hand.confidence,
            ),
          const AppGap.sm(),
          Text(
            l10n.cameraResultsTasksDone(
                report.completedTaskCount, report.totalTaskCount),
            style: theme.textTheme.bodySmall,
          ),
          if (report.retryCount > 0)
            Text(
              l10n.cameraResultsRetries(report.retryCount),
              style: theme.textTheme.bodySmall,
            ),
          const AppGap.sm(),
          for (final reason in report.confidenceReasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const AppGap.wide(AppSpacing.xs),
                  Expanded(
                    child: Text(reason, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _percentRow(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${(value * 100).round()}%',
              style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  // --- Per task, per hand ---

  Widget _taskSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    CameraTestReport report,
    CameraTaskType type,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_taskName(l10n, type), style: theme.textTheme.titleMedium),
          const AppGap.sm(),
          for (final hand in report.hands) ...[
            Text(
              hand.hand == 'Left' ? l10n.cameraHandLeft : l10n.cameraHandRight,
              style: theme.textTheme.labelLarge,
            ),
            const AppGap.xs(),
            ..._metricsFor(context, l10n, hand, type),
            const AppGap.sm(),
          ],
        ],
      ),
    );
  }

  List<Widget> _metricsFor(
    BuildContext context,
    AppLocalizations l10n,
    HandReport hand,
    CameraTaskType type,
  ) {
    final task = hand.taskOf(type);

    // A task that was not recorded well enough says so, rather than showing
    // numbers derived from a recording that cannot support them.
    //
    // Distinct from the per-feature "too few movements" below: one is the
    // camera failing to see the hand, which the patient can do something about,
    // and the other is the movement itself not supplying enough cycles. Both
    // used to render as a bare "Insufficient data", which told them nothing.
    if (task == null || !task.valid) {
      return <Widget>[
        _unavailable(context, l10n.cameraResultsNotRecorded,
            Icons.videocam_off_outlined),
      ];
    }

    if (type == CameraTaskType.rest) {
      final tremor = task.tremor;
      if (tremor == null) {
        return <Widget>[
          _unavailable(context, l10n.cameraResultsNotRecorded,
              Icons.videocam_off_outlined),
        ];
      }
      return <Widget>[
        _metric(context, l10n.cameraMetricTremorAmplitude,
            _palmWidths(l10n, tremor.amplitude)),
        _metric(
          context,
          l10n.cameraMetricTremorFrequency,
          tremor.dominantFrequencyHz == null
              ? l10n.cameraResultsInsufficient
              : l10n.cameraUnitHertz(
                  tremor.dominantFrequencyHz!.toStringAsFixed(1)),
        ),
        _metric(context, l10n.cameraMetricRestDuration,
            l10n.cameraUnitSeconds(task.usableSeconds.toStringAsFixed(1))),
      ];
    }

    final cycles = task.cycles;
    if (cycles == null) {
      return <Widget>[
        _unavailable(context, l10n.cameraResultsTooFewMovements,
            Icons.remove_circle_outline),
      ];
    }

    // Everything the analyzer produces regardless of whether it could pick out
    // individual movement cycles comes first.
    //
    // There used to be an early return here when no cycles were found, which
    // replaced the whole task with one grey line. That threw away the speed and
    // duration figures the analyzer had already computed and returned — the
    // most robust numbers in the pipeline — and was the reason a recording full
    // of real movement could come back showing nothing at all. Cycle detection
    // failing is a reason to omit the *cycle-derived* features, and nothing
    // more.
    final widgets = <Widget>[
      _metric(context, l10n.cameraMetricSpeed,
          _palmWidthsPerSecond(l10n, cycles.meanSpeed)),
      _metric(context, l10n.cameraMetricPeakSpeed,
          _palmWidthsPerSecond(l10n, cycles.maxSpeed)),
      _metric(context, l10n.cameraMetricCycles,
          l10n.cameraUnitCount('${cycles.cycleCount}')),
      _metric(context, l10n.cameraMetricRecordedTime,
          l10n.cameraUnitSeconds(cycles.durationSeconds.toStringAsFixed(1))),
    ];

    if (cycles.cycleCount == 0) {
      // Said once, rather than repeated against each feature it explains.
      widgets.add(_unavailable(context, l10n.cameraResultsTooFewMovements,
          Icons.remove_circle_outline));
      return widgets;
    }

    // Each of these is marked unavailable on its own when the movement did not
    // supply enough cycles for it, never as a blanket replacement for the task.
    return <Widget>[
      ...widgets,
      _metric(context, _rateLabel(l10n, type), _rate(l10n, cycles.rateHz)),
      _metric(context, l10n.cameraMetricAmplitude,
          _palmWidths(l10n, cycles.meanAmplitude)),
      _metric(context, l10n.cameraMetricRhythm,
          _fraction(l10n, cycles.rhythmVariability)),
      _metric(context, l10n.cameraMetricAmplitudeDecrement,
          _fraction(l10n, cycles.amplitudeDecrement)),
      _metric(context, l10n.cameraMetricSpeedDecrement,
          _fraction(l10n, cycles.speedDecrement)),
      _metric(context, l10n.cameraMetricPauses,
          l10n.cameraUnitCount('${cycles.pauseCount}')),
    ];
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const AppGap.wide(AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  /// A value that could not be produced, with the reason why.
  Widget _unavailable(BuildContext context, String reason, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const AppGap.wide(AppSpacing.xs),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  // --- Left versus right ---

  Widget _comparisonSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    CameraTestReport report,
  ) {
    final measured =
        report.comparisons.where((c) => c.measured).toList(growable: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cameraResultsDifference,
              style: theme.textTheme.titleMedium),
          const AppGap.sm(),
          if (measured.isEmpty)
            Text(l10n.cameraResultsNoComparison,
                style: theme.textTheme.bodyMedium)
          else
            for (final comparison in measured)
              _metric(
                context,
                _comparisonLabel(l10n, comparison.name),
                // Both sides shown, so the gap is read against the values it
                // came from rather than presented as a finding on its own.
                '${comparison.left!.toStringAsFixed(2)} · '
                '${comparison.right!.toStringAsFixed(2)}',
              ),
        ],
      ),
    );
  }

  // --- Labels and units ---

  String _taskName(AppLocalizations l10n, CameraTaskType type) {
    switch (type) {
      case CameraTaskType.rest:
        return l10n.cameraTaskRest;
      case CameraTaskType.openClose:
        return l10n.cameraTaskOpenClose;
      case CameraTaskType.fingerTap:
        return l10n.cameraTaskFingerTap;
      case CameraTaskType.pronationSupination:
        return l10n.cameraTaskPronation;
    }
  }

  String _rateLabel(AppLocalizations l10n, CameraTaskType type) {
    switch (type) {
      case CameraTaskType.fingerTap:
        return l10n.cameraMetricTapsPerSecond;
      case CameraTaskType.openClose:
        return l10n.cameraMetricMovementsPerSecond;
      case CameraTaskType.pronationSupination:
        return l10n.cameraMetricTurnsPerSecond;
      case CameraTaskType.rest:
        return l10n.cameraMetricSpeed;
    }
  }

  String _comparisonLabel(AppLocalizations l10n, String name) {
    switch (name) {
      case 'tap_rate':
        return l10n.cameraMetricTapsPerSecond;
      case 'tap_amplitude':
        return l10n.cameraMetricAmplitude;
      case 'open_close_rate':
        return l10n.cameraMetricMovementsPerSecond;
      case 'rotation_rate':
        return l10n.cameraMetricTurnsPerSecond;
      case 'speed':
        return l10n.cameraMetricSpeed;
      case 'rhythm_variability':
        return l10n.cameraMetricRhythm;
      case 'amplitude_decrement':
        return l10n.cameraMetricAmplitudeDecrement;
      case 'tremor_amplitude':
        return l10n.cameraMetricTremorAmplitude;
      default:
        return name;
    }
  }

  /// `null` renders as "insufficient data", never as zero.
  ///
  /// The distinction matters more here than anywhere else on the screen: 0.0
  /// amplitude decrement means "the movement held its size", while an
  /// unmeasurable one means "there were too few movements to tell". Showing the
  /// second as the first would turn missing evidence into a reassuring result.
  String _rate(AppLocalizations l10n, double? value) => value == null
      ? l10n.cameraResultsInsufficient
      : l10n.cameraUnitPerSecond(value.toStringAsFixed(2));

  String _palmWidths(AppLocalizations l10n, double? value) => value == null
      ? l10n.cameraResultsInsufficient
      : l10n.cameraUnitPalmWidths(value.toStringAsFixed(2));

  /// Speed of the movement signal.
  ///
  /// The one measure here that does not depend on individual movements being
  /// picked out — it is the mean rate of change of the whole task's signal — so
  /// it survives when everything else comes back unavailable.
  String _palmWidthsPerSecond(AppLocalizations l10n, double? value) =>
      value == null
          ? l10n.cameraResultsInsufficient
          : l10n.cameraUnitPalmWidthsPerSecond(value.toStringAsFixed(2));

  String _fraction(AppLocalizations l10n, double? value) => value == null
      ? l10n.cameraResultsInsufficient
      : l10n.cameraUnitPercent('${(value * 100).round()}');
}
