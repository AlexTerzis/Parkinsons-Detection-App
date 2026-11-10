import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../models/test_result.dart';
import '../../../models/test_score_interpretation.dart';
import '../app_semantic_colors.dart';
import '../app_tokens.dart';
import '../test_type_labels.dart';
import 'app_card.dart';
import 'app_section.dart';

/// One test result, as a clinician would want to read it.
///
/// Replaces a raw dump of the stored `data` map. That map is the analysis
/// pipeline's own record — dozens of keys, versioned, nested — and printing it
/// as `key: value` gave a doctor no way to see what actually happened without
/// reading JSON.
///
/// So: the test's name, when it was taken, the concern band, and the few
/// figures that matter for that kind of test. Everything else stays available
/// behind an expander rather than being deleted, because the detail is
/// occasionally exactly what is wanted.
class TestResultSummary extends StatelessWidget {
  const TestResultSummary({super.key, required this.result});

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Always read through concernScore, never the raw stored score: older
    // documents follow the opposite convention and this is what converts them.
    final double concern = result.concernScore;
    final band = TestScoreInterpretation.bandOfConcern(result.type, concern);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  testTypeLabel(l10n, result.type),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _BandChip(band: band, concern: concern, l10n: l10n),
            ],
          ),
          Text(
            _formatDate(result.performedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const AppGap.sm(),
          ..._highlights(context, l10n),
          if (result.data.isNotEmpty) ...[
            const AppGap.xs(),
            Theme(
              // Removes the divider lines an ExpansionTile draws by default,
              // which read as card boundaries inside a card.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.cameraDiagnosticsTitle,
                  style: theme.textTheme.labelLarge,
                ),
                children: [
                  for (final entry in result.data.entries)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xxs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${entry.value}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The handful of figures worth surfacing for this kind of test.
  ///
  /// Deliberately conservative: a key is only shown when it is present and
  /// numeric, so a test whose stored shape changes shows fewer rows rather than
  /// rendering `null` or crashing.
  List<Widget> _highlights(BuildContext context, AppLocalizations l10n) {
    // Only keys with an existing localized label. Adding English strings inside
    // a shared widget is how the Greek app ended up with English chart spokes.
    final labels = <String, String>{
      'overall_confidence': l10n.cameraResultsQuality,
      'recording_quality': l10n.cameraResultsQuality,
      'asymmetry': l10n.cameraMetricHandDifference,
      'mean_fps': l10n.cameraDiagFpsLabel,
    };

    final rows = <Widget>[];
    final seen = <String>{};
    for (final entry in labels.entries) {
      final value = result.data[entry.key];
      if (value is! num) continue;
      // Two keys can share a label across test types; show it once.
      if (!seen.add(entry.value)) continue;
      rows.add(_row(context, entry.value, _formatNumber(value)));
    }
    return rows;
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  static String _formatNumber(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  static String _formatDate(DateTime when) {
    final local = when.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}

/// The concern band, as a chip.
///
/// Never colour alone — the band is named as well, so it survives being read by
/// someone who cannot distinguish the colours.
class _BandChip extends StatelessWidget {
  const _BandChip({
    required this.band,
    required this.concern,
    required this.l10n,
  });

  final ScoreBand band;
  final double concern;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    // Same colour and label mapping the patient's results tab uses, so a band
    // does not mean one thing on one screen and another elsewhere.
    final (Color background, String label) = switch (band) {
      ScoreBand.reassuring => (semantic.success, l10n.bandLabelReassuring),
      ScoreBand.borderline => (semantic.warning, l10n.bandLabelBorderline),
      ScoreBand.notable =>
        (Theme.of(context).colorScheme.error, l10n.bandLabelNotable),
    };

    return Chip(
      backgroundColor: background.withValues(alpha: 0.18),
      side: BorderSide(color: background),
      label: Text('$label · ${(concern * 100).round()}%'),
    );
  }
}
