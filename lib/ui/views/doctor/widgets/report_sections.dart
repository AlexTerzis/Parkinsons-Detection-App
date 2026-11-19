import 'package:flutter/material.dart';

import '../../../../app/app.locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/patient_report.dart';
import '../../../../models/raison_result.dart';
import '../../../../models/test_result.dart';
import '../../../../models/test_score_interpretation.dart';
import '../../../../models/test_type.dart';
import '../../../../services/cognitive_facts.dart';
import '../../../../services/raison_api_service.dart';
import '../../../../services/report_analysis.dart';
import '../../../../services/test_series_analysis.dart';
import '../../../common/questionnaire_display.dart';
import '../../../common/test_type_labels.dart';
import '../../../common/widgets/test_result_summary.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience_view/widgets/score_charts.dart';

/// The sections that turn one report into something a clinician can read.
///
/// Two groups, deliberately unequal. The baseline assessments — MoCA, FAB and
/// the symptom questionnaire — are asked once and read directly, and MoCA and
/// FAB have published cut-offs behind them. Everything else is one of this
/// app's own repeated sensor measures, whose bands `TestScoreInterpretation`
/// itself documents as provisional, so those collapse into a level and a
/// direction rather than being listed reading by reading as though each were a
/// finding.
///
/// Each section renders nothing when it has nothing to say.

/// MoCA, FAB and the reported symptoms.
class BaselineAssessments extends StatelessWidget {
  const BaselineAssessments({super.key, required this.report});

  final PatientReport report;

  /// The keys each battery writes. See `neuro_test_viewmodel.dart:158` and
  /// `fab_test_viewmodel.dart:101`.
  static const Map<TestType, (String, String, int)> _batteryKeys = {
    TestType.neuro: ('mocaScore', 'mocaMax', 30),
    TestType.fab: ('fabScore', 'fabMax', 15),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final wheels = <Widget>[];
    for (final entry in _batteryKeys.entries) {
      final wheel = _batteryWheel(context, entry.key, entry.value);
      if (wheel != null) wheels.add(Expanded(child: wheel));
    }

    final questionnaire = _latestOf(TestType.questionnaire);
    if (wheels.isEmpty && questionnaire == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportBaselineTitle, style: theme.textTheme.titleMedium),
          const AppGap.xxs(),
          Text(
            l10n.reportBaselineExplainer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (wheels.isNotEmpty) ...[
            const AppGap.md(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: wheels,
            ),
          ],
          if (questionnaire != null) ...[
            const AppGap.md(),
            const Divider(height: 1),
            _QuestionnaireSections(result: questionnaire),
          ],
        ],
      ),
    );
  }

  /// One battery as a dial showing the score a clinician quotes.
  ///
  /// `24 of 30`, not a concern percentage. Both instruments have published
  /// cut-offs against their own scale, and rescaling them to this app's 0-1
  /// concern throws away the number the doctor recognises. The ring fills with
  /// *performance* so that fuller is better, while its colour comes from the
  /// band — a nearly-full ring cannot show green if the score is below cut-off.
  Widget? _batteryWheel(
    BuildContext context,
    TestType type,
    (String, String, int) keys,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final result = _latestOf(type);
    if (result == null) return null;

    final score = result.data[keys.$1];
    if (score is! num) return null;
    final max = result.data[keys.$2];
    final outOf = max is num ? max.toInt() : keys.$3;

    final attempts = report.results.where((r) => r.type == type).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScoreWheel(
          score: score.toInt(),
          outOf: outOf,
          label: testTypeLabel(l10n, type),
          color: bandColour(context, type, result.concernScore),
          // A repeat of the same form is not comparable to the first sitting:
          // the word list, the animals and the Luria sequences are remembered,
          // so a later score reads higher for reasons that have nothing to do
          // with the patient. Better said here than left for the doctor to
          // notice from the dates.
          caption: attempts > 1 ? l10n.reportRepeatWarning(attempts) : null,
        ),
        const AppGap.xs(),
        _BandChipFor(type: type, concern: result.concernScore),
      ],
    );
  }

  TestResult? _latestOf(TestType type) {
    TestResult? latest;
    for (final result in report.results) {
      if (result.type != type) continue;
      if (latest == null || result.performedAt.isAfter(latest.performedAt)) {
        latest = result;
      }
    }
    return latest;
  }
}

/// The questionnaire, grouped as the questionnaire itself groups it.
///
/// Every section is collapsed to a count and opens to the answers. The doctor
/// used to be shown the raw stored map — `A1`, `RBD_q`, `SCOPA>3` against
/// `true` — which is the shape the reasoning engine wants and is unreadable to
/// a human. Each id is now resolved to the question as it was asked.
class _QuestionnaireSections extends StatelessWidget {
  const _QuestionnaireSections({required this.result});

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final inGreek = Localizations.localeOf(context).languageCode == 'el';
    final sections = questionnaireSections(result.data, inGreek: inGreek);
    if (sections.isEmpty) return const SizedBox.shrink();

    final answered = sections.fold<int>(0, (n, s) => n + s.answers.length);
    final reported = sections.fold<int>(0, (n, s) => n + s.affirmativeCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppGap.sm(),
        Text(l10n.reportQuestionnaireTitle, style: theme.textTheme.labelLarge),
        const AppGap.xxs(),
        // States plainly that it was completed and how much of it said yes,
        // so the doctor knows whether opening a section is worth it.
        Text(
          l10n.reportQuestionnaireCompleted(answered, reported),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const AppGap.xs(),
        for (final section in sections)
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(section.name, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                l10n.reportSectionAnswered(
                  section.answers.length,
                  section.affirmativeCount,
                ),
                style: theme.textTheme.bodySmall,
              ),
              children: [
                for (final answer in section.answers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reported symptoms are marked, so a clinician can find
                        // them without reading every "no" in between.
                        Icon(
                          answer.affirmative
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          size: 16,
                          color: answer.affirmative
                              ? AppSemanticColors.of(context).warning
                              : theme.colorScheme.outline,
                        ),
                        const AppGap.wide(AppSpacing.xs),
                        Expanded(
                          child: Text(
                            answer.label,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const AppGap.wide(AppSpacing.xs),
                        Text(
                          answer.value,
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The colour a concern reads as for a given test.
///
/// One place, so a band never means one thing on a dial and another on a chip.
Color bandColour(BuildContext context, TestType type, double concern) {
  final semantic = AppSemanticColors.of(context);
  return switch (TestScoreInterpretation.bandOfConcern(type, concern)) {
    ScoreBand.reassuring => semantic.success,
    ScoreBand.borderline => semantic.warning,
    ScoreBand.notable => Theme.of(context).colorScheme.error,
  };
}

/// The app's own repeated measures, one collapsed row per test.
///
/// A doctor reading fourteen separate tremor scores learns less than one line
/// saying where they typically land and which way they have been going. The
/// individual readings are still there, one tap down, for when a particular
/// sitting is the question.
class RepeatedMeasures extends StatelessWidget {
  const RepeatedMeasures({super.key, required this.report});

  final PatientReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Falls back to summarising the report's own results when the document
    // predates summaries — see `PatientReport.seriesSummaries`.
    final series = report.seriesSummaries
        .where((s) => !TestSeriesAnalysis.isBaseline(s.type))
        .toList(growable: false);
    if (series.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportRepeatedTitle, style: theme.textTheme.titleMedium),
          const AppGap.xxs(),
          // Said plainly. These bands are this app's own reading, not a
          // validated instrument, and the layout should not imply otherwise
          // just by sitting next to MoCA and FAB.
          Text(
            l10n.reportRepeatedExplainer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const AppGap.sm(),
          _OverallVerdict(series: series),
          if (series.length >= 3) ...[
            const AppGap.sm(),
            ScoreRadarChart(
              scores: <String, double>{
                for (final s in series)
                  testTypeLabel(l10n, s.type): s.typicalConcern,
              },
            ),
          ],
          const AppGap.sm(),
          for (final summary in series)
            _SeriesTile(summary: summary, report: report),
        ],
      ),
    );
  }
}

/// Where the sensor tests land taken together, in one line.
///
/// The median of each test's own typical level, rather than a mean over every
/// reading: without it a test taken thirty times would outvote one taken twice,
/// and the answer would say more about which test the patient likes than about
/// the patient. Each test gets one vote.
///
/// Banded against `cameraDetection`, whose thresholds are the shared sensor
/// ones — the batteries and posture have their own cut-offs and are not part of
/// this figure.
class _OverallVerdict extends StatelessWidget {
  const _OverallVerdict({required this.series});

  final List<TestSeriesSummary> series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (series.isEmpty) return const SizedBox.shrink();

    final overall = TestSeriesAnalysis.median(
      series.map((s) => s.typicalConcern).toList(growable: false),
    );
    final color = bandColour(context, TestType.cameraDetection, overall);
    final band =
        TestScoreInterpretation.bandOfConcern(TestType.cameraDetection, overall);
    final label = switch (band) {
      ScoreBand.reassuring => l10n.bandLabelReassuring,
      ScoreBand.borderline => l10n.bandLabelBorderline,
      ScoreBand.notable => l10n.bandLabelNotable,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.summarize_outlined, color: color),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportOverallVerdict(label),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.reportOverallDetail(
                      (overall * 100).round(),
                      series.length,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One test's series: level and direction collapsed, readings inside.
class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.summary, required this.report});

  final TestSeriesSummary summary;
  final PatientReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final results = report.results
        .where((r) => r.type == summary.type)
        .toList(growable: false);

    return Theme(
      // Removes the divider lines an ExpansionTile draws by default, which read
      // as card boundaries inside a card.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          testTypeLabel(l10n, summary.type),
          style: theme.textTheme.titleSmall,
        ),
        subtitle: _DirectionLine(summary: summary),
        trailing: _BandChipFor(
          type: summary.type,
          concern: summary.typicalConcern,
        ),
        children: [
          if (results.length >= 2) ...[
            ScoreTrendChart(
              height: 140,
              curved: true,
              spots: spotsFromNewestFirst(
                results
                    .map((r) => ScorePoint(r.performedAt, r.concernScore))
                    .toList(growable: false),
              ),
            ),
            const AppGap.xs(),
          ],
          for (final result in results)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TestResultSummary(result: result),
            ),
        ],
      ),
    );
  }
}

/// How many sittings, and which way they have moved.
class _DirectionLine extends StatelessWidget {
  const _DirectionLine({required this.summary});

  final TestSeriesSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    // Concern falling is the patient improving, so the arrow follows the
    // concern and the word says what that means — the icon alone would read
    // backwards to anyone assuming "up is good".
    final (IconData icon, Color color, String label) = switch (summary.direction) {
      SeriesDirection.improving =>
        (Icons.trending_down, semantic.success, l10n.seriesImproving),
      SeriesDirection.worsening =>
        (Icons.trending_up, theme.colorScheme.error, l10n.seriesWorsening),
      SeriesDirection.stable =>
        (Icons.trending_flat, theme.colorScheme.onSurfaceVariant,
         l10n.seriesStable),
      SeriesDirection.tooFewToSay => (
          Icons.horizontal_rule,
          theme.colorScheme.onSurfaceVariant,
          l10n.seriesTooFew,
        ),
    };

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const AppGap.wide(AppSpacing.xxs),
        Expanded(
          child: Text(
            '${l10n.seriesSittings(summary.count)} · $label',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// A concern band as a chip, coloured and named.
class _BandChipFor extends StatelessWidget {
  const _BandChipFor({required this.type, required this.concern});

  final TestType type;
  final double concern;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = bandColour(context, type, concern);

    // Same mapping the patient's own results use, so a band does not mean one
    // thing on one screen and something else here.
    final label = switch (TestScoreInterpretation.bandOfConcern(type, concern)) {
      ScoreBand.reassuring => l10n.bandLabelReassuring,
      ScoreBand.borderline => l10n.bandLabelBorderline,
      ScoreBand.notable => l10n.bandLabelNotable,
    };

    return Chip(
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
      label: Text(label),
    );
  }
}

/// What the reasoning engine concludes from the questionnaire.
///
/// Re-run here rather than read off the report. The engine's output is never
/// persisted — the patient's app computes it at submit time and holds it in
/// memory — but the questionnaire's stored `data` *is* the answer map the
/// engine takes as input, so it can be asked again. That works for reports
/// already in the database, which carrying the conclusion on new documents
/// would not.
class ReasoningCard extends StatefulWidget {
  const ReasoningCard({super.key, required this.report});

  final PatientReport report;

  @override
  State<ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<ReasoningCard> {
  /// Started once and held, so a rebuild does not fire another network call.
  Future<List<RaisonResult>>? _future;

  @override
  void initState() {
    super.initState();
    final questionnaire = widget.report.results
        .where((r) => r.type == TestType.questionnaire)
        .firstOrNull;
    if (questionnaire == null || questionnaire.data.isEmpty) return;
    // The report carries copies of the patient's cognitive test results, so
    // the same facts the patient's own screen uses can be derived here.
    _future = locator<RaisonApiService>().submit(
      CognitiveFacts.merge(questionnaire.data, widget.report.results),
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.argumentation, style: theme.textTheme.titleMedium),
          const AppGap.xs(),
          FutureBuilder<List<RaisonResult>>(
            future: future,
            builder: (context, snapshot) {
              // A third-party network call, so every state is spelled out:
              // silence here would read as "the engine found nothing", which
              // is a different and much stronger claim than "it did not
              // answer".
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  l10n.loadingReasoning,
                  style: theme.textTheme.bodyMedium,
                );
              }
              if (snapshot.hasError) {
                return Text(
                  l10n.reasoningUnavailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }

              final solutions = (snapshot.data ?? const <RaisonResult>[])
                  .where((r) => r.isSolution)
                  .toList(growable: false);
              if (solutions.isEmpty) {
                return Text(
                  l10n.noArgumentationYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final solution in solutions) ...[
                    Text(solution.label, style: theme.textTheme.titleSmall),
                    const AppGap.xxs(),
                    for (final line in solution.explanation)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          bottom: AppSpacing.xxs,
                        ),
                        child:
                            Text('• $line', style: theme.textTheme.bodyMedium),
                      ),
                    const AppGap.sm(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// What this assessment could not tell anyone.
///
/// Deliberately prominent rather than a footnote. A report that shows four
/// good results and silently omits that the camera run measured nothing invites
/// a conclusion the data does not support.
class AssessmentGaps extends StatelessWidget {
  const AssessmentGaps({super.key, required this.report});

  final PatientReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    final gaps = ReportAnalysis.gapsIn(report);
    if (gaps.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 20, color: semantic.warning),
              const AppGap.wide(AppSpacing.xs),
              Expanded(
                child: Text(l10n.reportGapsTitle,
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const AppGap.xs(),
          for (final gap in gaps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                '• ${testTypeLabel(l10n, gap.type)} — ${_describe(l10n, gap)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  static String _describe(AppLocalizations l10n, AssessmentGap gap) {
    switch (gap.reason) {
      case GapReason.notTaken:
        return l10n.gapNotTaken;
      case GapReason.nothingMeasured:
        return l10n.gapNothingMeasured;
      case GapReason.partlyRecorded:
        return l10n.gapPartlyRecorded(
          gap.missingParts ?? 0,
          gap.totalParts ?? 0,
        );
      case GapReason.lowQuality:
        return l10n.gapLowQuality(((gap.quality ?? 0) * 100).round());
    }
  }
}
