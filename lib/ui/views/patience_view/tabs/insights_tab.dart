import 'package:flutter/material.dart';

import '../../../../app/app.locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/raison_result.dart';
import '../../../../models/test_result.dart';
import '../../../../models/test_type.dart';
import '../../../../services/authentication_service.dart';
import '../../../../services/cognitive_facts.dart';
import '../../../../services/raison_api_service.dart';
import '../../../../services/raison_plus_text.dart';
import '../../../../services/test_service.dart';
import '../../../common/widgets/widgets.dart';

/// Reasoning output and analytics summaries.
///
/// When [resultsFuture] is given (straight after the questionnaire is
/// submitted) it is shown as it is. Otherwise the tab runs the reasoning
/// itself, from the stored questionnaire and the latest cognitive tests, so
/// that a MoCA or FAB taken after the questionnaire is reflected the next
/// time the tab is opened.
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key, required this.resultsFuture});

  final Future<List<RaisonResult>>? resultsFuture;

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

/// What the reasoning on this screen rests on.
class _ReasoningInputs {
  const _ReasoningInputs({this.answers, this.moca, this.fab});

  /// Questionnaire answers with the cognitive facts merged in; null when no
  /// questionnaire has been submitted.
  final Map<String, dynamic>? answers;
  final TestResult? moca;
  final TestResult? fab;
}

class _InsightsTabState extends State<InsightsTab> {
  /// Started once and held, so a rebuild does not fire another network call.
  late final Future<_ReasoningInputs> _inputs;
  late final Future<List<RaisonResult>> _results;

  @override
  void initState() {
    super.initState();
    _inputs = _loadInputs();
    _results = widget.resultsFuture ??
        _inputs.then<List<RaisonResult>>((inputs) {
          final answers = inputs.answers;
          if (answers == null) return const <RaisonResult>[];
          return locator<RaisonApiService>().submit(answers);
        });
  }

  Future<_ReasoningInputs> _loadInputs() async {
    try {
      final uid = locator<AuthenticationService>().currentUser?.uid;
      if (uid == null) return const _ReasoningInputs();
      final results = await locator<TestService>().fetchResultsForPatient(uid);
      final questionnaire =
          CognitiveFacts.latest(results, TestType.questionnaire);
      return _ReasoningInputs(
        answers: questionnaire == null || questionnaire.data.isEmpty
            ? null
            : CognitiveFacts.merge(questionnaire.data, results),
        moca: CognitiveFacts.latest(results, TestType.neuro),
        fab: CognitiveFacts.latest(results, TestType.fab),
      );
    } catch (_) {
      // Without the inputs the tab falls back to "no questionnaire yet".
      return const _ReasoningInputs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _summaryCard(
          context,
          leading: const Text('🧠', style: TextStyle(fontSize: 28)),
          title: l10n.aiSummaryTitle,
          body: l10n.aiSummarySubtitle,
        ),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.testBreakdownTitle,
          body: l10n.testBreakdownSubtitle,
        ),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.riskAlertsTitle,
          body: l10n.noAlertsSubtitle,
        ),
        const AppGap.sm(),
        _argumentation(context),
        _inputsNote(context),
        const AppGap.sm(),
        _summaryCard(
          context,
          title: l10n.aiSuggestionsTitle,
          body: l10n.retakeTremorSuggestion,
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String body,
    Widget? leading,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading,
            const AppGap.wide(AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const AppGap.xxs(),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// States which inputs the advice above rests on.
  Widget _inputsNote(BuildContext context) {
    final theme = Theme.of(context);
    final greek = Localizations.localeOf(context).languageCode == 'el';
    String t(String english, String greekText) => greek ? greekText : english;
    String date(DateTime d) => '${d.day}/${d.month}/${d.year}';

    return FutureBuilder<_ReasoningInputs>(
      future: _inputs,
      builder: (context, snapshot) {
        final inputs = snapshot.data;
        if (inputs == null || inputs.answers == null) {
          return const SizedBox.shrink();
        }
        final moca = CognitiveFacts.mocaScore(inputs.moca);
        final fab = CognitiveFacts.fabScore(inputs.fab);
        final parts = [
          t('questionnaire', 'ερωτηματολόγιο'),
          moca == null
              ? t('cognitive test (MoCA-based) not taken',
                  'νευροψυχολογικό τεστ (MoCA): δεν έχει γίνει')
              : t('cognitive test (MoCA-based) $moca/30 on ${date(inputs.moca!.performedAt)}',
                  'νευροψυχολογικό τεστ (MoCA) $moca/30 στις ${date(inputs.moca!.performedAt)}'),
          fab == null
              ? t('FAB not taken', 'FAB: δεν έχει γίνει')
              : t('FAB $fab/15 on ${date(inputs.fab!.performedAt)}',
                  'FAB $fab/15 στις ${date(inputs.fab!.performedAt)}'),
        ];
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Text(
            '${t('Based on', 'Βασίζεται σε')}: ${parts.join('; ')}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  /// The reasoning engine's conclusions, once they resolve.
  Widget _argumentation(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<RaisonResult>>(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.noArgumentationYet,
          );
        }
        if (!snapshot.hasData) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.loadingReasoning,
          );
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.takeQuestionnairePrompt,
          );
        }

        final solutions =
            results.where((r) => r.isSolution).toList(growable: false);
        if (solutions.isEmpty) {
          return _summaryCard(
            context,
            title: l10n.argumentation,
            body: l10n.noArgumentationYet,
          );
        }

        final greek = Localizations.localeOf(context).languageCode == 'el';
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.argumentation, style: theme.textTheme.titleMedium),
              const AppGap.xs(),
              for (final r in solutions) ...[
                Text(RaisonPlusText.label(r.label, greek: greek),
                    style: theme.textTheme.titleSmall),
                const AppGap.xxs(),
                for (final e in r.explanation)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      bottom: AppSpacing.xxs,
                    ),
                    child: Text('• ${RaisonPlusText.line(e, greek: greek)}',
                        style: theme.textTheme.bodyMedium),
                  ),
                const AppGap.sm(),
              ],
            ],
          ),
        );
      },
    );
  }
}
