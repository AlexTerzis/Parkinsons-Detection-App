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
import '../../../common/widgets/diagnosis_indications_card.dart';
import '../../../common/widgets/reasoning_details.dart';
import '../../../common/widgets/widgets.dart';

/// Reasoning output and analytics summaries.
///
/// Two rAIson+ agents: the visit agent ("Argumentation") and, when its key is
/// configured, the diagnosis agent ("Possible indications"), which always
/// reasons from the stored questionnaire.
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

  /// Null when the diagnosis agent is not configured; resolves to null when
  /// no questionnaire has been submitted.
  Future<RaisonReasoning?>? _diagnosis;

  @override
  void initState() {
    super.initState();
    final raison = locator<RaisonApiService>();
    _inputs = _loadInputs();
    _results = widget.resultsFuture ??
        _inputs.then<List<RaisonResult>>((inputs) {
          final answers = inputs.answers;
          if (answers == null) return const <RaisonResult>[];
          return raison.submit(answers);
        });
    if (raison.diagnosisConfigured) {
      _diagnosis = _inputs.then<RaisonReasoning?>((inputs) {
        final answers = inputs.answers;
        if (answers == null) return null;
        return raison.diagnose(answers);
      });
    }
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
    // The AI summary, test breakdown, risk alerts and test suggestion cards
    // were fixed placeholder text that did not follow the results, so the tab
    // shows only what the reasoning actually produced.
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _argumentation(context),
        _inputsNote(context),
        if (_diagnosis != null) ...[
          const AppGap.sm(),
          DiagnosisIndicationsCard(future: _diagnosis!, forPatient: true),
        ],
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // Say what went wrong: a missing key, a used-up quota and an outage
          // need different fixes, and all used to read "no clear result".
          final greek = Localizations.localeOf(context).languageCode == 'el';
          final error = snapshot.error;
          final String body;
          if (error is RaisonQuotaExhausted) {
            body = greek
                ? 'Οι ερωτήσεις του rAIson+ για τη σύσταση επίσκεψης '
                    'εξαντλήθηκαν.'
                : 'The rAIson+ queries for the visit recommendation are used '
                    'up.';
          } else if (error is StateError) {
            body = greek
                ? 'Η σύνδεση με το rAIson+ δεν έχει ρυθμιστεί σε αυτή την '
                    'έκδοση της εφαρμογής.'
                : 'The connection to rAIson+ is not set up in this build of '
                    'the app.';
          } else {
            body = greek
                ? 'Η υπηρεσία rAIson+ δεν απάντησε. Δοκιμάστε ξανά αργότερα.'
                : 'The rAIson+ service did not answer. Try again later.';
          }
          debugPrint('🔍 [rAIson+] visit recommendation failed: $error');
          return _summaryCard(context, title: l10n.argumentation, body: body);
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

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.argumentation, style: theme.textTheme.titleMedium),
              const AppGap.xs(),
              for (final r in solutions) _recommendation(context, r),
            ],
          ),
        );
      },
    );
  }

  /// One recommendation for the patient: the decision, a sentence they can
  /// act on and the main reasons, with every rule folded under "How this
  /// was reached".
  Widget _recommendation(BuildContext context, RaisonResult r) {
    final theme = Theme.of(context);
    final greek = Localizations.localeOf(context).languageCode == 'el';
    final reasons =
        RaisonPlusText.mainReasons(r.label, r.explanation, greek: greek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(RaisonPlusText.label(r.label, greek: greek),
            style: theme.textTheme.titleSmall),
        const AppGap.xxs(),
        Text(RaisonPlusText.advice(r.label, greek: greek),
            style: theme.textTheme.bodyMedium),
        if (reasons.isNotEmpty) ...[
          const AppGap.xxs(),
          Text(
            '${greek ? 'Κυρίως λόγω' : 'Mainly because of'}: '
            '${reasons.join(', ')}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        ReasoningDetails(
          lines: [
            for (final e in r.explanation)
              RaisonPlusText.line(e, greek: greek),
          ],
        ),
      ],
    );
  }
}
