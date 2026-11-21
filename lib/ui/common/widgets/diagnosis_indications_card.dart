import 'package:flutter/material.dart';

import '../../../models/raison_result.dart';
import '../../../services/raison_api_service.dart';
import '../../../services/raison_plus_text.dart';
import 'widgets.dart';

/// The rAIson+ diagnosis agent's indications, in the app's language.
///
/// Used in the doctor's report and, framed for the patient, in the patient's
/// Insights tab. The indications come from self-reported answers and rules
/// written by doctors, and are not clinically validated, so both versions say
/// they are not a diagnosis. Several can hold at once, which is how the
/// doctors' table is written.
///
/// A [future] that resolves to null (no questionnaire yet) hides the card.
class DiagnosisIndicationsCard extends StatelessWidget {
  const DiagnosisIndicationsCard({
    super.key,
    required this.future,
    this.forPatient = false,
  });

  final Future<RaisonReasoning?> future;

  /// Patient wording, with the reasoning folded away under "How this was
  /// reached". The doctor's version shows the reasoning in full.
  final bool forPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greek = Localizations.localeOf(context).languageCode == 'el';
    String t(String english, String greekText) => greek ? greekText : english;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return FutureBuilder<RaisonReasoning?>(
      future: future,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        if (done && !snapshot.hasError && snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final Widget body;
        if (!done) {
          body = Text(t('Reasoning…', 'Γίνεται η συλλογιστική…'),
              style: theme.textTheme.bodyMedium);
        } else if (snapshot.hasError) {
          body = Text(
            snapshot.error is RaisonQuotaExhausted
                ? t('The rAIson+ queries for this agent are used up.',
                    'Οι ερωτήσεις του rAIson+ για αυτόν τον πράκτορα '
                        'εξαντλήθηκαν.')
                : t('The service did not answer. Try again later.',
                    'Η υπηρεσία δεν απάντησε. Δοκιμάστε ξανά αργότερα.'),
            style: muted,
          );
        } else {
          body = _result(context, snapshot.data!, greek: greek);
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forPatient
                    ? t('Possible indications', 'Πιθανές ενδείξεις')
                    : t('Diagnostic indications', 'Διαγνωστικές ενδείξεις'),
                style: theme.textTheme.titleMedium,
              ),
              const AppGap.xxs(),
              Text(
                forPatient
                    ? t(
                        'Not a diagnosis. They come from your answers and '
                            'rules written by doctors, and are not clinically '
                            'validated. Talk them over with your doctor.',
                        'Δεν είναι διάγνωση. Προκύπτουν από τις απαντήσεις '
                            'σας και από κανόνες που έγραψαν γιατροί, και δεν '
                            'έχουν επικυρωθεί κλινικά. Συζητήστε τες με τον '
                            'γιατρό σας.',
                      )
                    : t(
                        'Indications for the doctor to consider, not a '
                            'diagnosis. They come from the patient\'s own '
                            'answers and are not clinically validated.',
                        'Ενδείξεις προς εξέταση από τον γιατρό, όχι '
                            'διάγνωση. Προκύπτουν από τις απαντήσεις του '
                            'ασθενούς και δεν έχουν επικυρωθεί κλινικά.',
                      ),
                style: theme.textTheme.bodySmall,
              ),
              const AppGap.xs(),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _result(
    BuildContext context,
    RaisonReasoning reasoning, {
    required bool greek,
  }) {
    final theme = Theme.of(context);
    final indications = reasoning.indications;
    if (indications.isEmpty) {
      return Text(
        forPatient
            ? (greek
                ? 'Καμία ένδειξη από τις απαντήσεις σας.'
                : 'No indication from your answers.')
            : (greek
                ? 'Καμία ένδειξη με τις απαντήσεις που δόθηκαν.'
                : 'No indication from the answers given.'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final reasons = [
      for (final line in reasoning.explanation)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            bottom: AppSpacing.xxs,
          ),
          child: Text(
            RaisonPlusText.line(line, greek: greek),
            style: theme.textTheme.bodySmall,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in indications)
          Text(
            '• ${RaisonPlusText.label(d, greek: greek)}',
            style: theme.textTheme.titleSmall,
          ),
        if (reasons.isNotEmpty) ...[
          const AppGap.xs(),
          if (forPatient)
            ExpansionTile(
              title: Text(
                greek ? 'Πώς προέκυψε' : 'How this was reached',
                style: theme.textTheme.bodyMedium,
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              shape: const Border(),
              collapsedShape: const Border(),
              children: reasons,
            )
          else
            ...reasons,
        ],
      ],
    );
  }
}
